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

# TBC - uniform use of log_xxx (pach_mgmt.rb) instead of Chef::Log.xxx
# TBC - uniform use of log_xxx starting by [vios]?
# TBC - uniform info message on STDOUT with puts (like Start/Finish key operation)
# TBC - should we add color in error message (like in pach_mgmt.rb: perform_efix_vios_customization)?
# TBC - should we check the properties (mandatory) before starting operations?
#       should we have only one exception for BadProporty for example?
#       exceptions: ViosUpdateBadRemoveParam, VioslppSourceNotFound, VioslppSourceBadLocation, etc.

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
property :updateios_flags, ['install', 'commit', 'reject', 'cleanup', 'remove']
property :accept_licenses, ['yes', 'no'], default: 'yes'
property :preview, ['yes', 'no'], default: 'yes'
property :action_list, String, default: "check,altdisk_copy,update" # no altdisk_cleanup by default
property :time_limit, String

default_action :update

##############################
# load_current_value
##############################
load_current_value do
end

##############################
# DEFINITIONS
##############################
class InvalidActionListProperty < StandardError
end

class InvalidTimeLimitProperty < StandardError
end

class VioslppSourceNotFound < StandardError
end

class VioslppSourceBadLocation < StandardError
end

class ViosHealthCheckError < StandardError
end

class ViosUpdateBadRemoveParam < StandardError
end

class ViosUpdateError < StandardError
end

# -----------------------------------------------------------------
# Check the vioshc script can be used
#
#    return 0 if success, the number of issues otherwise
# -----------------------------------------------------------------
def check_vioshc
  ret = 0
  vioshc_file = '/usr/sbin/vioshc.py'

  unless ::File.exist?(vioshc_file)
    Chef::Log.warn("Error: Health check script file '#{vioshc_file}': not found")
    ret += 1
  end

  unless ::File.executable?(vioshc_file)
    Chef::Log.warn("Error:Health check script file '#{vioshc_file}': not executable")
    ret += 1
  end

  ret
end

# -----------------------------------------------------------------
# Check the specified lpp_source location exists
#
#    return true if success
#    raise  VioslppSourceNotFound in case of error
#    raise  VioslppSourceBadLocation in case of error
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
  raise VioslppSourceNotFound, "Error: Command \"#{cmd_s}\" returns above error. Cannot find location of lpp_source \#{lpp_source}" if !exit_status.success?

  # check to make sure path exists
  raise VioslppSourceBadLocation, "Error: Cannot find location '{#location}' of lpp_source '#{lpp_source}'" unless Dir.exist?(location)

  log_warn("Warning: the lpp_source '#{lpp_source}' location '#{location}' is empty") if Dir.entries(location).size == 2

  ret
end

# -----------------------------------------------------------------
# Check the "health" of the given VIOSES for a rolling update point of view
#
# This operation uses the vioshc.py script to evaluate the capacity of the
# pair of the VIOSes to support the rolling update operation:
# - check they manage the same LPARs,
#
#    Return 0 if success
#    raise ViosHealthCheckError in case of error
# -----------------------------------------------------------------
def vios_health_init(nim_vios, hmc_id, hmc_login, hmc_ip)
  log_info("vios_health_init: hmc_id='#{hmc_id}', hmc_ip='#{hmc_ip}'")
  ret = 0

  # Call the /usr/sbin/vioshc.py script a first time to collect UUIDs
  cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -l a"
  log_info("vios_health_init: '#{cmd_s}'")
  Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stderr.each_line do |line|
      # nothing is print on stderr so far but log anyway
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    unless wait_thr.value.success?
      stdout.each_line { |line| log_info("[STDOUT] #{line.chomp}") }
      raise ViosHealthCheckError, "Error: Command \"#{cmd_s}\" returns above error!"
    end

    data_start = 0
    vios_section = 0
    cec_uuid = ''
    cec_serial = ''

    # Parse the output and store the UUIDs
    stdout.each_line do |line|
      log_info("[STDOUT] #{line.chomp}")
      if line.include? "ERROR"
        log_warn("Heath check (vioshc.py) script error: '#{line.strip}'")
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
            log_warn("Unexpected Heath check script output: consecutive Managed Systems UUIDs: '#{line.strip}'")
          end
          cec_uuid = Regexp.last_match(1)
          cec_serial = Regexp.last_match(2).gsub('*', '_')
          log_debug("vios_health_init - New managed system: cec_uuid:'#{cec_uuid}', cec_serial:'#{cec_serial}'")
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
            log_info("vios_health_init - matching vios #{vios_key}: vios_part_id='#{vios_part_id}' vios_uuid='#{vios_uuid}'")
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

      raise ViosHealthCheckError, "Health init check failed. Bad Heath check command output for the #{hmc_id} hmc - output: '#{line}'"
    end
  end
  ret
end

# -----------------------------------------------------------------
# Health assessment of the VIOSes targets to ensure they can be support
#    a rolling update operation.
#
#    For each VIOS tuple,
#    - call /usr/sbin/vioshc.py a first time to collect the VIOS UUIDs
#    - call it a second time to check the healthiness
#
#    return: 0 if ok, 1 otherwise
# -----------------------------------------------------------------
def vios_health_check(nim_vios, hmc_login, hmc_ip, vios_list)
  log_debug("vios_health_check: hmc_ip: #{hmc_ip} vios_list: #{vios_list}")
  ret = 0
  rate = 0
  msg = ""

  # Call the /usr/sbin/vioshc.py script
  cmd_s = "/usr/sbin/vioshc.py -i #{hmc_ip} -m #{nim_vios[vios_list[0]]['cec_uuid']} "
  vios_list.each do |vios|
    cmd_s << "-U #{nim_vios[vios]['vios_uuid']} "
  end

  log_debug("vios_health_check: '#{cmd_s}'")
  Open3.popen3({ 'LANG' => 'C' }, cmd_s) do |_stdin, stdout, stderr, wait_thr|
    stderr.each_line do |line|
      STDERR.puts line
      log_info("[STDERR] #{line.chomp}")
    end
    ret = 1 unless wait_thr.value.success?

    stdout.each_line do |line|
      log_info("[STDOUT] #{line.chomp}")

      if line =~ /^ERROR:(.*)$/ and msg == ""
        msg = Regexp.last_match(1)
      end
      next unless line =~ /Pass rate of/

      rate = Regexp.last_match(1).to_i if line =~ /Pass rate of (\d+)%/

      if ret == 0 && rate == 100
        log_info("VIOSes #{vios_list.join('-')} can be updated")
      else
        msg = "Warning: VIOSes #{vios_list.join('-')} can NOT be updated: only #{rate}% of checks pass"
        STDERR.puts msg
        log_warn("#{msg}")
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
#    raise ViosUpdateBadRemoveParam in case of error
#    raise VioslppSourceNotFound from check_lpp_source
#    raise VioslppSourceBadLocation from check_lpp_source
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
      attr_found = false
      if !filesets.nil? && !filesets.emty? && fileset.downcase != "none"
        cmd << " -a filesets=#{filesets}"
        if !installp_bundle.nil? && !installp_bundle.emty? && installp_bundle != "none"
          raise ViosUpdateBadRemoveParam, "Error: 'filesets' and 'installp_bundle' attribute are exclusive when 'updateios_flags' is 'remove'."
        end
        attr_found = true
      end
      if !installp_bundle.nil? && !installp_bundle.emty? && installp_bundle != "none"
        cmd << " -a installp_bundle=#{installp_bundle}"
        if !filesets.nil? && !filesets.emty? && fileset.downcase != "none"
          raise ViosUpdateBadRemoveParam, "Error: 'filesets' and 'installp_bundle' attribute are exclusive when 'updateios_flags' is 'remove'."
        end
        attr_found = true
      end
      raise ViosUpdateBadRemoveParam, "Error: 'filesets' or 'installp_bundle' attribute must be specified when 'updateios_flags' is 'remove'." unless attr_found
    else
      if (!filesets.nil? && !filesets.emty?) || (!installp_bundle.nil? && !installp_bundle.emty?)
        log_info('updateios command: filesets and installp_bundle parameters have been discarded')
      end
    end
  else
    raise ViosUpdateBadRemoveParam, "Error: updateios_flags attribute is mandatory for update."
  end

  # preview mode
  if !preview.nil? && !preview.empty?
    cmd << " -a preview=#{preview}"
  else
    # default
    cmd << ' -a preview=yes'
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
  puts "Start updating vios '#{vios}' with nim updateios."
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
  puts "Finish updating vios '#{vios}'."

  raise ViosUpdateError, "Failed to perform NIM updateios operation on '#{vios}', see above error!" unless exit_status.success?
end


##############################
# ACTION: update
##############################
action :update do
  # inputs
  Chef::Log.info("VIOS UPDATE - desc=\"#{desc}\"")
  Chef::Log.info("VIOS UPDATE - action_list=\"#{action_list}\"")
  Chef::Log.info("VIOS UPDATE - targets=#{targets}")
  Chef::Log.info("VIOS UPDATE - altdisks=#{altdisks}")
  STDOUT.puts ""
  STDERR.puts ""  # TBC - need for message presentation

  # check mandatory property
  allowed_action = ["check", "altdisk_copy", "update", "altdisk_cleanup"]
  action_list.gsub(' ','').split(',').each do |my_action|
    unless allowed_action.include?(my_action)
      raise InvalidActionListProperty, "Error: Invalid action '#{my_action}' in action_list '#{action_list}', must be in: #{allowed_action.join(',')}"
    end
  end
  if (action_list.include?("altdisk_copy") || action_list.include?("altdisk_cleanup")) && altdisks.nil?
    raise InvalidAltdiskProperty, "Please specify an 'altdisks' property for altdisk operation"
  end

  # build time object from time_limit attribute,
  end_time = nil
  if !time_limit.nil?
    if time_limit =~ /^(\d{2})\/(\d{2})\/(\d{2,4}) (\d{1,2}):(\d{1,2})$/
      end_time = Time.local(Regexp.last_match(3).to_i, Regexp.last_match(2).to_i, Regexp.last_match(1).to_i, Regexp.last_match(4).to_i, Regexp.last_match(5).to_i)
      log_info("end_time: '#{end_time}'")
      next
    else
      raise InvalidTimeLimitProperty, "Error: 'time_limit' property must be 'mm/dd/yy HH:MM', got:'#{time_limit}'"
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
  log_warn("Empty alternate hdisk hash for altdisks #{altdisks}") if !altdisks.nil? && altdisk_hash.empty?

  # check vioshc script is executable
  check_vioshc

  targets_status = {}
  vios_key = {}
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
    # Credentials
    log_info("Credentials (for VIOS: #{vios1})")
    cec_serial = nim_vios[vios1]['mgmt_cec_serial']
    hmc_id = nim_vios[vios1]['mgmt_hmc_id']

    if !nim_hmc.has_key?(hmc_id)
      log_warn("VIOS Update: - HMC ID '#{hmc_id}' for VIOS '#{vios1}' refers to an inexistant HMC #{hmc_id}")
      targets_status[vios_key] = 'FAILURE-HC'
      next
    end

    hmc_login = nim_hmc[hmc_id]['login']
    hmc_passfile = nim_hmc[hmc_id]['passwd_file']
    hmc_ip = nim_hmc[hmc_id]['ip']
    hmc_login_len = hmc_login.length

    ###############
    # health_check
    if action_list.include?('check')
      log_info("VIOS Health Check operation for VIOS tuple: #{target_tuple}")


      # if needed call vios_health_init to get the UUIDs value
      if !nim_vios[vios1].has_key?('vios_uuid') ||
        tup_len == 2 && !nim_vios[vios2].has_key?('vios_uuid')
        begin
          vios_health_init(nim_vios, hmc_id, hmc_login, hmc_ip)
        rescue ViosHealthCheckError => e
          STDERR.puts e.message
          log_warn("#{e.message}")
        end
        # Error case is handle by the next if statement
      end

      if tup_len == 1 && nim_vios[vios1].has_key?('vios_uuid') ||
         tup_len == 2 && nim_vios[vios1].has_key?('vios_uuid') && nim_vios[vios2].has_key?('vios_uuid')

        # run the vios_health check for the vios tuple
        ret = vios_health_check(nim_vios, hmc_login, hmc_ip, vios_list)

        # TBC-B - For testing, will be remove !!!!!!!!!!!!!!!!!
        ret = 1 if vios1 == 'gdrh9v1' || vios1 == 'gdrh9v2'
        #ret = 0 if vios1 == 'gdrh10v1' || vios1 == 'gdrh10v2'
        # TBC-E

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
        msg = "Error: VIOS Health Check did not get the UUID of VIOS: #{vios_err}"
        log_warn("msg")
        STDERR.puts msg
      end

      log_info("VIOS Health Check status for #{vios_key}: #{targets_status[vios_key]}")
    end    # check


    ###############
    # Alternate disk copy operation

    # check previous status and skip if failure
    if action_list.include?('altdisk_copy')
      log_info("VIOS altdisk copy operation for VIOS tuple: #{target_tuple}")

      # if health check status is known, check the vios tuple has passed
      if action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        log_warn("#{vios_key} vioses skipped (previous status: #{targets_status[vios_key]}")
        next
      end

      # check if there is time to handle this tuple
      if end_time.nil? || Time.now <= end_time
        # first find the right hdisk and check if we can perform the copy
        ret = 0
        vios_list.each do |vios|
          log_info("VIOS altdisk copy, check/find disk for vios #{vios}")
          begin
            vio_server.get_disk_for_altdisk_copy(nim_vios, vios, altdisk_hash)
          rescue AltDiskFindError => e
            STDERR.puts e.message
            targets_status[vios_key] = if vios == vios1
                                         'FAILURE-ALTDCOPY1'
                                       else
                                         'FAILURE-ALTDCOPY2'
                                       end
            break
          end
          ret += 1
        end
        next unless ret == 2    # if 2 valid disk cannot be found, skip the copy

        # actually perform the alternate disk copy
        vios_list.each do |vios|
          log_info("VIOS altdisk copy, perform the copy for vios #{vios}")
          converge_by("nim: perform alt_disk_install for vios '#{vios}' on disk '#{altdisk_hash[vios]}'\n") do
            begin
              puts "Start NIM alt_disk_install operation for disk '#{altdisk_hash[vios]}' on vios '#{vios}'."
              nim.perform_altdisk_install(vios, "rootvg", altdisk_hash[vios])
            rescue NimAltDiskInstallError => e
              msg = "Failed to start the alternate disk copy on #{altdisk_hash[vios]}"
              STDERR.puts e.message
              STDERR.puts "#{msg} of #{vios}"
              log_warn("[#{vios}] #{msg}")
              targets_status[vios_key] = if vios == vios1
                                           'FAILURE-ALTDCOPY1'
                                         else
                                           'FAILURE-ALTDCOPY2'
                                         end
              break
            end

            # wait the end of the alternate disk copy operation
            begin
              ret = nim.wait_alt_disk_install(vios)
            rescue NimLparInfoError => e
              STDERR.puts e.message
              log_warn("[#{vios}] #{e.message}")
              ret = 1
            rescue NimAltDiskInstallTimedOut => e
              STDERR.puts e.message
              msg = "Alternate disk copy failed on #{altdisk_hash[vios]}: timed out"
              log_warn("[#{vios}] #{msg}")
              STDERR.puts "#{msg} on vios #{vios}"
              ret = 1
            rescue NimAltDiskInstallError => e
              STDERR.puts e.message
              msg = "Alternate disk copy failed on #{altdisk_hash[vios]}"
              log_warn("[#{vios}] #{msg}")
              STDERR.puts "#{msg} on vios #{vios}"
              ret = 1
            end

            if ret == 0
              targets_status[vios_key] = 'SUCCESS-ALTDC'
              log_info("[#{vios}] VIOS altdisk copy succeeded on #{altdisk_hash[vios]}")
            else
              targets_status[vios_key] = if vios == vios1
                                           'FAILURE-ALTDCOPY1'
                                         else
                                           'FAILURE-ALTDCOPY2'
                                         end
            end
            puts "Finish NIM alt_disk_install operation for disk '#{altdisk_hash[vios]}' on vios '#{vios}': #{targets_status[vios_key]}."
            break unless ret == 0
          end
        end
      else
        log_warn("#{vios_key} vioses skipped: time limit '#{time_limit}' reached")
      end

      log_info("VIOS altdisk copy status for #{vios_key}: #{targets_status[vios_key]}")
    end    # altdisk_copy


    ########
    # update
    if action_list.include?('update')
      log_info("VIOS update operation for VIOS tuple: #{target_tuple}")

      if action_list.include?('altdisk_copy') && targets_status[vios_key] != 'SUCCESS-ALTDC' ||
        !action_list.include?('altdisk_copy') && action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        log_warn("#{vios_key} vioses skipped (previous status: #{targets_status[vios_key]}")
        next
      end

      begin
        cmd = get_updateios_cmd(accept_licenses, updateios_flags, filesets, installp_bundle, preview)
      rescue ViosUpdateBadRemoveParam, VioslppSourceNotFound, VioslppSourceBadLocation => e
        STDERR.puts e.message
        log_warn("#{e.message}")
        targets_status[vios_key] = "FAILURE-UPDT1"
        log_info("VIOS update status for #{vios_key}: #{targets_status[vios_key]}")
        break # cannot continue, will skip cleanup anyway
      end
      targets_status[vios_key] = "SUCCESS-UPDT"
      vios_list.each do |vios|
        # set the error label
        err_label = "FAILURE-UPDT1"
        if vios != vios1
          err_label = "FAILURE-UPDT2"
        end
        cmd_to_run = cmd + vios
        converge_by("nim: perform NIM updateios for vios '#{vios}'\n") do
          begin
            nim_updateios(vios, cmd_to_run)
          rescue ViosUpdateError => e
            STDERR.puts e.message
            log_warn("[#{vios}] #{e.message}")
            targets_status[vios_key] = err_label
            break
          end
        end
      end
      log_info("VIOS update status for #{vios_key}: #{targets_status[vios_key]}")
    end    # update


    ###############
    # Alternate disk cleanup operation
    if action_list.include?('altdisk_cleanup')
      log_info("VIOS altdisk cleanup operation for VIOS tuple: #{target_tuple}")

      # check previous status and skip if failure
      if action_list.include?('update') && targets_status[vios_key] != 'SUCCESS-UPDT' ||
         !action_list.include?('update') && action_list.include?('altdisk_copy') && targets_status[vios_key] != 'SUCCESS-ALTDC' ||
         !action_list.include?('update') && !action_list.include?('altdisk_copy') && action_list.include?('check') && targets_status[vios_key] != 'SUCCESS-HC'
        log_warn("#{vios_key} vioses skipped (previous status: #{targets_status[vios_key]}")
        next
      end

      ret = 0
      vios_list.each do |vios|
        converge_by("vios: cleanup altinst_rootvg for vios '#{vios}' on disk '#{altdisk_hash[vios]}'\n") do

          log_info("VIOS altdisk cleanup, get a valid disk for vios #{vios}")
          begin
            ret = vio_server.get_altinst_rootvg_disk(nim_vios, vios, altdisk_hash)
          rescue AltDiskFindError => e
            STDERR.puts e.message
            ret = 1
            targets_status[vios_key] = if vios == vios1
                                         'FAILURE-ALTDCLEAN1'
                                       else
                                         'FAILURE-ALTDCLEAN2'
                                       end
          end
          log_info("Taking '#{altdisk_hash[vios]}' for altdisk_cleanup of '#{vios}'.") if ret == 0
          next unless ret == 0    # skip the cleanup as cannot found the disk

          # perform the alternate disk cleanup
          targets_status[vios_key] = if vios == vios1
                                       'FAILURE-ALTDCOPY1'
                                     else
                                       'FAILURE-ALTDCOPY2'
                                     end
          begin
            ret = vio_server.altdisk_copy_cleanup(nim_vios, vios, altdisk_hash)
          rescue AltDiskCleanError => e
            STDERR.puts e.message
            msg = "Failed to cleanup altdisk on disk #{altdisk_hash[vios]}"
            STDERR.puts "#{msg} of #{vios}"
            log_warn("[#{vios}] #{msg}")
          end
          if ret == 0
            targets_status[vios_key] = if vios == vios1
                                         'SUCCESS-ALTDCLEAN1'
                                       else
                                         'SUCCESS-ALTDCLEAN2'
                                       end
            log_info("[#{vios}] VIOS altdisk cleanup succeeded on #{altdisk_hash[vios]}")
          end
          puts "\nCleanup operation for disk '#{altdisk_hash[vios]}' on vios '#{vios}': #{targets_status[vios_key]}."
        end
      end
      log_info("VIOS altdisk cleanup status for #{vios_key}: #{targets_status[vios_key]}")
    end    # altdisk_cleanup

  end    # target_list.each
end
