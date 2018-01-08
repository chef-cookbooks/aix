#
# Copyright 2017, International Business Machines Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# TBC - uniform use of log_xxx instead of Chef::Log.xxx in previous code
# TBC - uniform use of put_xxx (pach_mgmt.rb) in previous code
# TBC - add color in exception error message?
# TBC - Should we use Mixlib::ShellOut.new(cmd_s) instead of popen3 in nim_updateios?

include AIX::PatchMgmt

##############################
# PROPERTIES
##############################
property :desc, String, name_property: true
property :targets, String, required: true
property :altdisks, String
property :filesets, String
property :installp_bundle, String
property :lpp_source, String
property :updateios_flags, String, equal_to: %w(install commit cleanup remove) # TBC - reject is not currently supported
property :accept_licenses, String, default: 'yes', equal_to: %w(yes no)
property :preview, default: 'yes', equal_to: %w(yes no)
property :action_list, String, default: 'check,altdisk_copy,update' # no altdisk_cleanup by default
property :time_limit, String # mm/dd/YY HH:MM
property :disk_size_policy, String, default: 'nearest', equal_to: %w(minimize upper lower nearest)

default_action :update

##############################
# load_current_value
##############################
load_current_value do
end

##############################
# DEFINITIONS
##############################
class ViosUpdateBadProperty < StandardError
end

class VioslppSourceBadLocation < StandardError
end

class ViosHealthCheckError < StandardError
end

class ViosUpdateError < StandardError
end

# -----------------------------------------------------------------
# Check the vioshc script can be used
#
#    return 0 if success
#
#    raise ViosHealthCheckError in case of error
# -----------------------------------------------------------------
def check_vioshc
  vioshc_file = '/usr/sbin/vioshc.py'

  unless ::File.exist?(vioshc_file)
    msg = "Error: Health check script file '#{vioshc_file}': not found"
    raise ViosHealthCheckError, msg
  end

  unless ::File.executable?(vioshc_file)
    msg = "Error: Health check script file '#{vioshc_file}' not executable"
    raise ViosHealthCheckError, msg
  end

  return 0
end

# -----------------------------------------------------------------
# Check the specified lpp_source location exists
#
#    return true if success
#
#    raise ViosUpdateBadProperty in case of error
#    raise VioslppSourceBadLocation in case of error
# -----------------------------------------------------------------
def check_lpp_source(lpp_source)
  location = ""
  ret = true

  # find location of lpp_source
  cmd_s = "/usr/sbin/lsnim -a location #{lpp_source}"
  log_info("check_lpp_source: '#{cmd_s}'")
  exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stdout.each_line do |line|
      log_info("[STDOUT] #{line.chomp}")
      location = Regexp.last_match(1) if line =~ /.*location\s+=\s+(\S+)\s*/
    end
    stderr.each_line do |line|
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    wait_thr.value # Process::Status object returned.
  end
  raise ViosUpdateBadProperty, "Cannot find location of lpp_source='#{lpp_source}': Command '#{cmd_s}' returns above error." if !exit_status.success?

  # check to make sure path exists
  raise VioslppSourceBadLocation, "Cannot find location='#{location}' of lpp_source='#{lpp_source}'" unless Dir.exist?(location)

  log_warn("The location='#{location}' of lpp_source='#{lpp_source}' is empty") if Dir.entries(location).size == 0

  ret
end

# -----------------------------------------------------------------
# Collect VIOS and Managed System UUIDs.
#
#    This first call to the vioshc.py script intend to collect
#    UUIDs. The actual health assessment is performed in a second
#    call.
#
#    Return 0 if success
#
#    raise ViosHealthCheckError in case of error
# -----------------------------------------------------------------
def vios_health_init(nim_vios, hmc_id, hmc_ip)
  log_debug("vios_health_init: hmc_id='#{hmc_id}', hmc_ip='#{hmc_ip}'")
  ret = 0

  # first call to collect UUIDs
  cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -l a"
  log_info("Health Check: init command '#{cmd_s}'")

  Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stderr.each_line do |line|
      # nothing is print on stderr so far but log anyway
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    unless wait_thr.value.success?
      stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
      raise ViosHealthCheckError, "Heath check init command \"#{cmd_s}\" returns above error!"
    end

    data_start = 0
    vios_section = 0
    cec_uuid = ''
    cec_serial = ''

    # Parse the output and store the UUIDs
    stdout.each_line do |line|
      log_info("[STDOUT] #{line.chomp}")
      if line.include?("ERROR") || line.include?("WARN")
        # Needed this because vioshc.py script does not prints error to stderr
        put_warn("Heath check (vioshc.py) script: '#{line.strip}'")
        next
      end
      line.rstrip!

      if vios_section == 0
        # skip the header
        if line =~ /^-+\s+-+$/
          data_start = 1
          next
        end
        next if data_start == 0

        # New managed system section
        if line =~ /^(\S+)\s+(\S+)\s*$/
          unless cec_uuid == "" && cec_serial == ""
            put_warn("Health Check: unexpected script output: consecutive Managed System UUID: '#{line.strip}'")
          end
          cec_uuid = Regexp.last_match(1)
          cec_serial = Regexp.last_match(2).gsub('*', '_')

          log_info("Health Check: init found managed system: cec_uuid:'#{cec_uuid}', cec_serial:'#{cec_serial}'")
          next
        end

        # New vios section
        if line =~ /^\s+-+\s+-+$/
          vios_section = 1
          next
        end

        # skip all header and empty lines until the vios section
        next
      end

      # new vios partition but skip if lparid is not found.
      next if line =~ /^\s+(\S+)\s+Not found$/

      # regular new vios partition
      if line =~ /^\s+(\S+)\s+(\S+)$/
        vios_uuid = Regexp.last_match(1)
        vios_part_id = Regexp.last_match(2)

        # retrieve the vios with the vios_part_id and the cec_serial value
        # and store the UUIDs in the dictionaries
        nim_vios.keys.each do |vios_key|
          if nim_vios[vios_key]['mgmt_vios_id'] == vios_part_id &&
             nim_vios[vios_key]['mgmt_cec_serial'] == cec_serial
            nim_vios[vios_key]['vios_uuid'] = vios_uuid
            nim_vios[vios_key]['cec_uuid'] = cec_uuid

            log_info("Health Check: init found matching vios #{vios_key}: vios_part_id='#{vios_part_id}' vios_uuid='#{vios_uuid}'")
            break
          end
        end
        next
      end

      # skip empty line after vios section. stop the vios section
      if line =~ /^\s*$/
        vios_section = 0
        cec_uuid = ""
        cec_serial = ""
        next
      end

      raise ViosHealthCheckError, "Health Check: init failed, bad script output for the #{hmc_id} hmc: '#{line}'"
    end
  end
  ret
end

# -----------------------------------------------------------------
# Health assessment of the VIOSes targets to ensure they can support
#    a rolling update operation.
#
#    This operation uses the vioshc.py script to evaluate the capacity
#    of the pair of the VIOSes to support the rolling update operation:
#
#    return: 0 if ok, 1 otherwise
# -----------------------------------------------------------------
def vios_health_check(nim_vios, hmc_ip, vios_list)
  log_debug("vios_health_check: hmc_ip: #{hmc_ip} vios_list: #{vios_list}")
  ret = 0
  rate = 0
  msg = ""

  cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -m #{nim_vios[vios_list[0]]['cec_uuid']} "
  vios_list.each do |vios|
    cmd_s << "-U #{nim_vios[vios]['vios_uuid']} "
  end
  log_info("Health Check: init command '#{cmd_s}'")

  Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stderr.each_line do |line|
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    ret = 1 unless wait_thr.value.success?

    # Parse the output to get the "Pass rate"
    stdout.each_line do |line|
      log_info("[STDOUT] #{line.chomp}")

      if line.include?("ERROR") || line.include?("WARN")
        # Need because vioshc.py script does not prints error to stderr
        put_warn("Heath check (vioshc.py) script: '#{line.strip}'")
      end
      next unless line =~ /Pass rate of/

      rate = Regexp.last_match(1).to_i if line =~ /Pass rate of (\d+)%/

      if ret == 0 && rate == 100
        put_info("VIOSes #{vios_list.join('-')} can be updated")
      else
        put_warn("VIOSes #{vios_list.join('-')} can NOT be updated: only #{rate}% of checks pass")
        ret = 1
      end
      break
    end
  end

  ret
end

# -----------------------------------------------------------------
# Build the NIM updateios command to run
#
#    return the command string to pass to nim_updateios()
#
#    raise ViosUpdateBadProperty in case of error
#    raise VioslppSourceBadLocation in case of error
# -----------------------------------------------------------------
def get_updateios_cmd(accept_licenses, updateios_flags, filesets, installp_bundle, preview)
  cmd = '/usr/sbin/nim -o updateios'
  lpp_source_param = false

  # lpp_source
  if !lpp_source.nil? && !lpp_source.empty? && check_lpp_source(lpp_source)
    cmd << " -a lpp_source=#{lpp_source}"
    lpp_source_param = true
  end

  # accept licenses
  if !accept_licenses.nil? && !accept_licenses.empty?
    cmd << " -a accept_licenses=#{accept_licenses}"
  else
    # default
    cmd << ' -a accept_licenses=yes'
  end

  # updateios flags
  if !updateios_flags.nil? && !updateios_flags.empty?
    cmd << " -a updateios_flags=-#{updateios_flags}"

    if updateios_flags == 'remove'
      if !filesets.nil? && !filesets.emty? && fileset.downcase != "none"
        cmd << " -a filesets=#{filesets}"
      end
      if !installp_bundle.nil? && !installp_bundle.emty? && installp_bundle != "none"
        cmd << " -a installp_bundle=#{installp_bundle}"
      end
    else
      if (!filesets.nil? && !filesets.emty?) || (!installp_bundle.nil? && !installp_bundle.emty?)
        put_info('updateios command: filesets and installp_bundle parameters have been discarded')
      end
    end
  end

  # preview mode
  if !preview.nil? && !preview.empty?
    cmd << " -a preview=#{preview} "
  else
    # default
    cmd << ' -a preview=yes '
  end

  log_debug("get_updateios_cmd - return cmd: '#{cmd}'")
  cmd
end

# -----------------------------------------------------------------
# Run the NIM updateios operation on specified vios
# The command to run is built by get_updateios_cmd()
#
#    raise ViosUpdateError in case of error
# -----------------------------------------------------------------
def nim_updateios(vios, cmd_s)
  # TBC - Why not use  nim = Mixlib::ShellOut.new(cmd_s) like in resources/nim.rb?
  put_info("Start updating vios '#{vios}' with NIM updateios.")
  log_info("nim_updateios: '#{cmd_s}'")
  # TBC - For testing, will be remove after test !!!
  #cmd_s = "/usr/sbin/lsnim -Z -a Cstate -a info -a Cstate_result #{vios}"
  #log_info("nim_updateios: overwrite cmd_s:'#{cmd_s}'")
  exit_status = Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
    stderr.each_line do |line|
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    wait_thr.value # Process::Status object returned.
  end
  put_info("Finish updating vios '#{vios}'.")

  raise ViosUpdateError, "Failed to perform NIM updateios operation on '#{vios}', see above error!" unless exit_status.success?
end

# -----------------------------------------------------------------
# Check the SSP status of the VIOS tuple
# Alternate disk copy can only be done when both VIOSes in the tuple
#     refer to the same cluster and have the same SSP status
#
#    ret = 0 if OK
#          1 else
# -----------------------------------------------------------------
def get_vios_ssp_status(nim_vios, vios_list, vios_key, targets_status)
  ssp_name = ""
  vios_ssp_status = ""
  vios_name = ""
  err_label = "FAILURE-SSP"
  ret = -1

  vios_list.each do |vios|
    nim_vios[vios]['ssp_status'] = "none"
  end

  # get the SSP status
  vios_list.each do |vios|
#  vios = vios_list[0]
    cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[vios]['vios_ip']} \"/usr/ios/cli/ioscli cluster -status -fmt :\""

    log_debug("ssp_status: '#{cmd_s}'")
    Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
      stderr.each_line do |line|
        STDERR.puts line
        log_info("[STDERR] #{line.chomp}")
      end
      unless wait_thr.value.success?
        stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
        msg = "Failed to get SSP status of #{vios_key}"
        log_warn("[#{vios}] #{msg}")
        raise ViosCmdError, "Error: #{msg} on #{vios}, command \"#{cmd_s}\" returns above error!"
      end

      # check that the VIOSes belong to the same cluster and have the same satus
      #                  or there is no SSP
      # stdout is like:
      # gdr_ssp3:OK:castor_gdr_vios3:8284-22A0221FD4BV:17:OK:OK
      # gdr_ssp3:OK:castor_gdr_vios2:8284-22A0221FD4BV:16:OK:OK
      #  or
      # Cluster does not exist.
      #
      stdout.each_line do |line|
        log_debug("[STDOUT] #{line.chomp}")
        line.chomp!
        if line =~ /^Cluster does not exist.$/
          log_debug("There is no cluster or the node #{vios} is DOWN")
          nim_vios[vios]['ssp_vios_status'] = "DOWN"
          if vios_list.length == 1
            return 0
          else
            next
          end
        end

        if line =~ /^(\S+):(\S+):(\S+):\S+:\S+:(\S+):.*/
          cur_ssp_name = Regexp.last_match(1)
          cur_ssp_satus = Regexp.last_match(2)
          cur_vios_name = Regexp.last_match(3)
          cur_vios_ssp_status = Regexp.last_match(4)

          if vios_list.include?(cur_vios_name)
            nim_vios[cur_vios_name]['ssp_vios_status'] = cur_vios_ssp_status
            nim_vios[cur_vios_name]['ssp_name'] = cur_ssp_name
            # single VIOS case
            if vios_list.length == 1
              if cur_vios_ssp_status == "OK"
                err_msg = "SSP is active for the single VIOS: #{cur_vios_name}. VIOS cannot be updated"
                put_error(err_msg)
                return 1
              else
                return 0
              end
            elsif cur_ssp_satus == "DEGRADED"
              err_msg = "SSP #{cur_ssp_name} is working in degraded mode then VIOS: #{vios} cannot be updated"
              put_error(err_msg)
              return 1
            end
            # first VIOS in the pair
            if ssp_name == ""
              ssp_name = cur_ssp_name
              vios_name = cur_vios_name
              vios_ssp_status = cur_vios_ssp_status
              next
            end

            # both VIOSes found
            if vios_ssp_status != cur_vios_ssp_status
              err_msg = "SSP status is not the same for the both VIOSes: (#{vios_key}). VIOSes cannot be updated"
              put_error(err_msg)
              return 1
            elsif ssp_name != cur_ssp_name && cur_vios_ssp_status == "OK"
              err_msg = "Both VIOSes: #{vios_key} does not belong to the same SSP. VIOSes cannot be updated"
              put_error(err_msg)
              return 1
            else
              return 0
            end
            break
          else
            # Compute here the case where SSP vios member does not belong to vios list
            ret = 1
          end
        end
      end
    end
  end
  if ret == -1
    if ssp_name == ""
      # VIOSes doesn't belong to any SSP
      ret = 0
    else
      ret = 1
      err_msg = "Only one VIOS belongs to an SSP. VIOSes cannot be updated"
    end
  end

  if ret == 1
    put_error(err_msg)
    targets_status[vios_key] = err_label
  end
  ret
end

# -----------------------------------------------------------------
# Stop/start the SSP for a VIOS
#
#    ret = 0 if OK
#          1 else
# -----------------------------------------------------------------
def ssp_stop_start(vios_list, vios, nim_vios, action)
  # if action is start SSP,  find the first node running SSP
  node = vios
  if action == 'start'
    vios_list.each do |n|
      if nim_vios[n]['ssp_vios_status'] == "OK"
        node = n
        break
      end
    end
  end
  cmd_s = "/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{nim_vios[node]['vios_ip']} \"/usr/sbin/clctrl -#{action} -n #{nim_vios[vios]['ssp_name']} -m #{vios}\""

  log_debug("ssp_stop_start: '#{cmd_s}'")
  Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stderr.each_line do |line|
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    unless wait_thr.value.success?
      stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
      msg = "Failed to #{action} cluster #{nim_vios[vios]['ssp_name']} on vios #{vios}"
      log_warn(msg)
      raise ViosCmdError, "#{msg}, command: \"#{cmd_s}\" returns above error!"
    end
  end

  nim_vios[vios]['ssp_vios_status'] = if action == 'stop'
                                        "DOWN"
                                      else
                                        "OK"
                                      end
  log_info("#{action} cluster #{nim_vios[vios]['ssp_name']} on vios #{vios} succeed")

  return 0
end


##############################
# ACTION: update
##############################
action :update do
  # inputs
  log_info("VIOS UPDATE - desc=\"#{desc}\"")
  log_info("VIOS UPDATE - action_list=\"#{action_list}\"")
  log_info("VIOS UPDATE - targets=#{targets}")
  STDOUT.puts ""
  STDERR.puts ""  # TBC - need for message presentation

  # check the action_list property
  allowed_action = ["check", "altdisk_copy", "update", "altdisk_cleanup"]
  action_list.gsub(' ','').split(',').each do |my_action|
    unless allowed_action.include?(my_action)
      raise ViosUpdateBadProperty, "Invalid action '#{my_action}' in action_list '#{action_list}', must be in: #{allowed_action.join(',')}"
    end
  end

  # check mandatory properties for the action_list
  if action_list.include?("altdisk_copy") && (altdisks.nil? || altdisks.empty?)
    raise ViosUpdateBadProperty, "Please specify an 'altdisks' property for altdisk_copy operation"
  end

  if action_list.include?('update')
    raise ViosUpdateBadProperty, "filesets is required for the update remove operation" if (filesets.nil? || filesets.empty?) && updateios_flags == "remove"
    raise ViosUpdateBadProperty, "lpp_source is required for the update operation"      if lpp_source.nil? || lpp_source.empty?
    raise ViosUpdateBadProperty, "updateios_flags is required for the update operation"  if updateios_flags.nil? || updateios_flags.empty?

    if updateios_flags == 'remove'
      attr_found = false
      if !filesets.nil? && !filesets.emty? && fileset.downcase != "none" &&
         !installp_bundle.nil? && !installp_bundle.emty? && installp_bundle != "none"
        raise ViosUpdateBadProperty, "'filesets' and 'installp_bundle' properties are exclusive when 'updateios_flags' is 'remove'."
        attr_found = true
      end
      if !installp_bundle.nil? && !installp_bundle.emty? && installp_bundle != "none" &&
         !filesets.nil? && !filesets.emty? && fileset.downcase != "none"
        raise ViosUpdateBadProperty, "'filesets' and 'installp_bundle' properties are exclusive when 'updateios_flags' is 'remove'."
        attr_found = true
      end
      raise ViosUpdateBadProperty, "'filesets' or 'installp_bundle' property must be specified when 'updateios_flags' is 'remove'." unless attr_found
    end
  end

  # build time object from time_limit attribute,
  end_time = nil
  if !time_limit.nil?
    if time_limit =~ /^(\d{2})\/(\d{2})\/(\d{2,4}) (\d{1,2}):(\d{1,2})$/
      end_time = Time.local(Regexp.last_match(3).to_i, Regexp.last_match(2).to_i, Regexp.last_match(1).to_i, Regexp.last_match(4).to_i, Regexp.last_match(5).to_i)
      log_info("End time for operation: '#{end_time}'")
    else
      raise ViosUpdateBadProperty, "Error: 'time_limit' property must be in the format: 'mm/dd/yy HH:MM', got:'#{time_limit}'"
    end
  end

  log_info("Check NIM info is well configured")
  nim = Nim.new
  check_nim_info(node)

  # get hmc info
  log_info("Get NIM info for HMC")
  nim_hmc = nim.get_hmc_info()

  # get the vios info
  log_info("Get NIM info for VIOSes")
  nim_vios = nim.get_nim_clients_info('vios')
  vio_server = VioServer.new

  # build array of vios
  log_info("List of VIOS known in NIM: #{nim_vios.keys}")

  # build list of targets
  altdisk_hash = {}
  target_list = expand_vios_pair_targets(targets, nim_vios.keys, altdisks, altdisk_hash)

  # check vioshc script is executable
  check_vioshc if action_list.include?('check')

  # main loop on target: can be 1-tuple or 2-tuple of VIOS
  targets_status = {}
  vios_key = ""
  target_list.each do |target_tuple|
    log_info("Working on target tuple: #{target_tuple}")

    vios_list = target_tuple.split(',')
    tup_len = vios_list.length
    vios1   = vios_list[0]
    if tup_len == 2
      vios2    = vios_list[1]
      vios_key = "#{vios1}-#{vios2}"
    else
      vios_key = vios1
      vios2   = nil
    end

    ###############
    # health_check
    if action_list.include?('check')
      Chef::Log.info("VIOS UPDATE - action=altdisk_copy")
      put_info("Health Check for VIOS tuple: #{target_tuple}")

      # Credentials
      log_info("Credentials (for VIOS: #{vios1})")
      cec_serial = nim_vios[vios1]['mgmt_cec_serial']
      hmc_id = nim_vios[vios1]['mgmt_hmc_id']

      if !nim_hmc.has_key?(hmc_id)
        # this should not happen
        put_error("Health Check, VIOS '#{vios1}' NIM management HMC ID '#{hmc_id}' not found")
        targets_status[vios_key] = 'FAILURE-HC'
        next # continue with next target tuple
      end

      hmc_login = nim_hmc[hmc_id]['login']
      hmc_ip = nim_hmc[hmc_id]['ip']

      # if needed call vios_health_init to get the UUIDs value
      if !nim_vios[vios1].has_key?('vios_uuid') ||
        tup_len == 2 && !nim_vios[vios2].has_key?('vios_uuid')
        begin
          vios_health_init(nim_vios, hmc_id, hmc_ip)
        rescue ViosHealthCheckError => e
          targets_status[vios_key] = 'FAILURE-HC'
          put_error(e.message)
        end
        # Error case is handle by the next if statement
      end

      if tup_len == 1 && nim_vios[vios1].has_key?('vios_uuid') ||
         tup_len == 2 && nim_vios[vios1].has_key?('vios_uuid') && nim_vios[vios2].has_key?('vios_uuid')

        # run the vios_health check for the vios tuple
        ret = vios_health_check(nim_vios, hmc_ip, vios_list)

        targets_status[vios_key] = if ret == 0
                                     'SUCCESS-HC'
                                   else
                                     'FAILURE-HC'
                                   end
      else
        # vios uuid's not found
        if !nim_vios[vios1].has_key?('vios_uuid') && !nim_vios[vios2].has_key?('vios_uuid')
          vios_err = "#{vios1} and #{vios2}"
        elsif !nim_vios[vios1].has_key?('vios_uuid')
          vios_err = vios1 unless nim_vios[vios1].has_key?('vios_uuid')
        else
          vios_err = vios2 unless nim_vios[vios2].has_key?('vios_uuid')
        end
        targets_status[vios_key] = 'FAILURE-HC'
        msg = "Health Check did not get the UUID of VIOS: #{vios_err}"
        put_error(msg)
      end

      log_info("Health Check status for #{vios_key}: #{targets_status[vios_key]}")

      next if targets_status[vios_key] == 'FAILURE-HC' # continue with next target tuple

    end    # check


    ###############
    # Alternate disk copy operation

    # check previous status and skip if failure
    if action_list.include?('altdisk_copy')
      log_info("VIOS UPDATE - action=altdisk_copy")
      log_info("VIOS UPDATE - altdisks=#{altdisks}")
      log_info("VIOS UPDATE - disk_size_policy=#{disk_size_policy}")
      log_info("Alternate disk copy for VIOS tuple: #{target_tuple}")

      # if health check status is known, check the vios tuple has passed
      if action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        put_warn("Alternate disk copy for #{vios_key} VIOSes skipped (previous status: #{targets_status[vios_key]})")
        next
      end

      # check if there is time to handle this tuple
      if end_time.nil? || Time.now <= end_time
        # first find the right hdisk and check if we can perform the copy
        ret = 0

        begin
          ret = vio_server.find_valid_altdisk(nim_vios, vios_list, vios_key, targets_status, altdisk_hash, disk_size_policy)
          if ret == 1
            next
          end
        rescue AltDiskFindError => e
          put_error(e.message)
          put_info("Finish NIM alt_disk_install operation for disk '#{altdisk_hash[vios_key]}' on vios '#{vios_key}': #{targets_status[vios_key]}.")
          next
        end

        # actually perform the alternate disk copy
        vios_list.each do |vios|
          converge_by("nim: perform alt_disk_install for vios '#{vios}' on disk '#{altdisk_hash[vios]}'\n") do
            begin
              put_info("Start NIM alt_disk_install operation using disk '#{altdisk_hash[vios]}' on vios '#{vios}'.")
              nim.perform_altdisk_install(vios, "rootvg", altdisk_hash[vios])
            rescue NimAltDiskInstallError => e
              msg = "Failed to start the alternate disk copy on #{altdisk_hash[vios]} of #{vios}: #{e.message}"
              put_error(msg)
              targets_status[vios_key] = if vios == vios1
                                           'FAILURE-ALTDCOPY1'
                                         else
                                           'FAILURE-ALTDCOPY2'
                                         end
              put_info("Finish NIM alt_disk_install operation using disk '#{altdisk_hash[vios]}' on vios '#{vios}': #{targets_status[vios_key]}.")
              break
            end

            # wait the end of the alternate disk copy operation
            begin
              ret = nim.wait_alt_disk_install(vios)
            rescue NimLparInfoError => e
              STDERR.puts e.message
              log_warn("[#{vios}] #{e.message}")
              ret = 1
            end
            if ret == 0
              targets_status[vios_key] = 'SUCCESS-ALTDC'
              log_info("[#{vios}] VIOS altdisk copy succeeded on #{altdisk_hash[vios]}")
            else
              if ret == 1
                STDERR.puts e.message
                msg = "Alternate disk copy failed on #{altdisk_hash[vios]} of vios #{vios}"
                put_error(msg)
                ret = 1
              else
                msg = "Alternate disk copy failed on #{altdisk_hash[vios]}: timed out"
                put_warn(msg)
                STDERR.puts "#{msg} on vios #{vios}"
              end
              ret = 1

              targets_status[vios_key] = if vios == vios1
                                           'FAILURE-ALTDCOPY1'
                                         else
                                           'FAILURE-ALTDCOPY2'
                                         end
            end
            put_info("Finish NIM alt_disk_install operation for disk '#{altdisk_hash[vios]}' on vios '#{vios}': #{targets_status[vios_key]}.")
            break unless ret == 0
          end
        end
      else
        put_warn("Alternate disk copy for #{vios_key} skipped: time limit '#{time_limit}' reached")
      end

      log_info("Alternate disk copy status for #{vios_key}: #{targets_status[vios_key]}")
    end    # altdisk_copy


    ########
    # update
    if action_list.include?('update')
      log_info("VIOS UPDATE - action=update")
      log_info("VIOS UPDATE - lpp_source=#{lpp_source}")
      log_info("VIOS UPDATE - updateios_flags=#{updateios_flags}")
      log_info("VIOS UPDATE - accept_licenses=#{accept_licenses}")
      log_info("VIOS UPDATE - preview=#{preview}")
      log_info("VIOS update operation for VIOS tuple: #{target_tuple}")

      if action_list.include?('altdisk_copy') && targets_status[vios_key] != 'SUCCESS-ALTDC' ||
        !action_list.include?('altdisk_copy') && action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        put_warn("Update of #{vios_key} vioses skipped (previous status: #{targets_status[vios_key]})")
        next
      end

      # check if there is time to handle this tuple
      if end_time.nil? || Time.now <= end_time
        ret = 0

        # check SSP status of the tuple
        # Alternate disk copy can only be done when both VIOSes in the tuple
        # have the same SSP status
        begin
          ret = get_vios_ssp_status(nim_vios, vios_list, vios_key, targets_status)
        rescue ViosCmdError => e
          put_error(e.message)
          targets_status[vios_key] = "FAILURE-UPDT1"
          log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
          break # cannot continue
        end
        if ret == 1
          put_warn("Update operation for #{vios_key} vioses skipped due to bad SSP status")
          put_info("Update operation can only be done when both of the VIOSes have the same SSP status (or for a single VIOS, when the SSP status is inactive) and belong to the same SSP")
          next
        end

        begin
          cmd = get_updateios_cmd(accept_licenses, updateios_flags, filesets, installp_bundle, preview)
        rescue ViosUpdateBadProperty, VioslppSourceBadLocation => e
          put_error("Update #{vios_key}: #{e.message}")
          targets_status[vios_key] = "FAILURE-UPDT1"
          log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
          break # cannot continue, will skip cleanup anyway
        end

        targets_status[vios_key] = "SUCCESS-UPDT"
        vios_list.each do |vios|
          # set the error label
          err_label = "FAILURE-UPDT1"
          if vios != vios1
            err_label = "FAILURE-UPDT2"
          end

          # if needed stop the SSP for the VIOS
          restart_needed = false
          if nim_vios[vios]['ssp_vios_status'] == 'OK'
            begin
              ret = ssp_stop_start(vios_list, vios, nim_vios, 'stop')
            rescue ViosCmdError => e
              put_error(e.message)
              targets_status[vios_key] = "FAILURE-UPDT1"
              log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
              break # cannot continue
            end
            restart_needed = true

            log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
            break if ret == 1
          end

          break_required = false
          cmd_to_run = cmd + vios
          converge_by("nim: perform NIM updateios for vios '#{vios}'\n") do
            begin
              put_info("Start NIM updateios for vios '#{vios}'.")
              nim_updateios(vios, cmd_to_run)
            rescue ViosUpdateError => e
              put_error(e.message)
              targets_status[vios_key] = err_label
              put_info("Finish NIM updateios for vios '#{vios}': #{targets_status[vios_key]}.")

              # in case of failure try to restart the SSP if needed
              break_required = true
            end
          end

          # if needed restart the SSP for the VIOS
          if restart_needed
            begin
              ret = ssp_stop_start(vios_list, vios, nim_vios, 'start')
            rescue ViosCmdError => e
              put_error(e.message)
              targets_status[vios_key] = "FAILURE-UPDT1"
              log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
              break # cannot continue
            end

            log_info("Update status for #{vios_key}: #{targets_status[vios_key]}")
            break if ret == 1
          end

          break if break_required

        end
      else
        put_warn("Update #{vios_key} skipped: time limit '#{time_limit}' reached")
      end

      log_info("Update status for vios '#{vios_key}': #{targets_status[vios_key]}.")
    end    # update


    ###############
    # Alternate disk cleanup operation
    if action_list.include?('altdisk_cleanup')
      log_info("VIOS UPDATE - action=altdisk_cleanup")
      log_info("VIOS UPDATE - altdisks=#{altdisks}")
      log_info("Alternate disk cleanup for VIOS tuple: #{target_tuple}")

      # check previous status and skip if failure
      if action_list.include?('update') && targets_status[vios_key] != 'SUCCESS-UPDT' ||
         !action_list.include?('update') && action_list.include?('altdisk_copy') && targets_status[vios_key] != 'SUCCESS-ALTDC' ||
         !action_list.include?('update') && !action_list.include?('altdisk_copy') && action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        put_warn("Alternate disk cleanup for #{vios_key} VIOSes skipped (previous status: #{targets_status[vios_key]}")
        next
      end

      # find the altinst_rootvg disk
      ret = 0
      vios_list.each do |vios|
        log_info("Alternate disk cleanup, get the alternate rootvg disk for vios #{vios}")
        begin
          ret = vio_server.get_altinst_rootvg_disk(nim_vios, vios, altdisk_hash)
        rescue AltDiskFindError => e
          put_error(msg)
          ret = 1
          targets_status[vios_key] = if vios == vios1
                                       'FAILURE-ALTDCLEAN1'
                                     else
                                       'FAILURE-ALTDCLEAN2'
                                     end
        end
        put_warn("Failed to get the alternate disk on #{vios}") unless ret == 0
      end

      # perform the alternate disk cleanup
      vios_list.select {|k| altdisk_hash[k] != ""}.each do |vios|
        converge_by("vios: cleanup altinst_rootvg disk on vios '#{vios}'\n") do
          targets_status[vios_key] = if vios == vios1
                                       'FAILURE-ALTDCOPY1'
                                     else
                                       'FAILURE-ALTDCOPY2'
                                     end
          begin
            ret = vio_server.altdisk_copy_cleanup(nim_vios, vios, altdisk_hash)
          rescue AltDiskCleanError => e
            msg = "Cleanup failed: #{e.message}"
            put_error(msg)
          end
          if ret == 0
            targets_status[vios_key] = if vios == vios1
                                         'SUCCESS-ALTDCLEAN1'
                                       else
                                         'SUCCESS-ALTDCLEAN2'
                                       end
            log_info("Alternate disk cleanup succeeded on #{altdisk_hash[vios]} of #{vios}")
          else
            put_warn("Failed to clean the alternate disk on #{altdisk_hash[vios]} of #{vios}") unless ret == 0
          end
        end
      end

      log_info("Alternate disk cleanup status for #{vios_key}: #{targets_status[vios_key]}")
    end    # altdisk_cleanup

  end    # target_list.each
end
