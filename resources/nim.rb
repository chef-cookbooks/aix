#
# Copyright 2016, International Business Machines Corporation
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

include AIX::PatchMgmt

##############################
# PROPERTIES
##############################
property :desc, String, name_property: true
property :lpp_source, String, required: true
property :targets, String
property :async, [true, false], default: false
property :device, String, required: true
property :script, String
property :resource, String
property :location, String
property :group, String
property :force, [true, false], default: false

##############################
# ACTION: update
##############################
action :update do
  # inputs
  Chef::Log.debug("desc=\"#{new_resource.desc}\"")
  Chef::Log.debug("lpp_source=#{new_resource.lpp_source}")
  Chef::Log.debug("targets=#{new_resource.targets}")
  Chef::Log.debug("async=#{new_resource.async}")
  Chef::Log.debug("force=#{new_resource.force}")

  check_nim_info(node)

  # force latest_sp/tl synchronously
  if property_is_set?(:async) && (new_resource.lpp_source == 'latest_tl' || new_resource.lpp_source == 'latest_sp')
    Chef::Log.warn('Force customization synchronously')
    local_async = false
  else
    local_async = new_resource.async
  end

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  # force interim fixes automatic removal
  if property_is_set?(:force) && new_resource.force == true
    target_list.each do |m|
      fixes = list_fixes(m)
      fixes.each do |fix|
        remove_fix(m, fix)
        Chef::Log.warn("Interim fix #{fix} has been automatically removed")
      end
    end
  end

  # nim install
  nim = Nim.new
  if local_async
    check_lpp_source_name(new_resource.lpp_source, node)
    converge_by("nim: perform asynchronous software customization for client(s) \'#{target_list.join(' ')}\' with resource \'#{new_resource.lpp_source}\'") do
      nim.perform_async_customization(new_resource.lpp_source, target_list.join(' '))
    end
  else # synchronous update
    target_list.each do |m|
      # get current oslevel
      current_oslevel = m == 'master' ? node['nim']['master']['oslevel'] : node['nim']['clients'][m]['oslevel']
      Chef::Log.debug("current_oslevel: #{current_oslevel}")
      if current_oslevel.nil? || current_oslevel.empty?
        Chef::Log.warn("Cannot get oslevel for machine #{m}")
        next
      end
      current_oslevel = current_oslevel.split('-')

      # get lpp source
      if new_resource.lpp_source == 'latest_tl' || new_resource.lpp_source == 'latest_sp'
        lpp_source_array = new_resource.lpp_source.split('_')
        time = lpp_source_array[0]
        type = lpp_source_array[1]
        new_lpp_source = find_resource_by_client(type, time, current_oslevel, node)
        Chef::Log.debug("new_lpp_source: #{new_lpp_source}")
      else
        check_lpp_source_name(new_resource.lpp_source, node)
        new_lpp_source = new_resource.lpp_source
      end

      # extract oslevel from lpp source
      oslevel = new_lpp_source.to_s.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})-lpp_source$/)[1]
      Chef::Log.debug("oslevel: #{oslevel}")
      if oslevel.nil? || oslevel.empty?
        Chef::Log.warn("Cannot extract oslevel from lpp source name #{new_lpp_source}")
        next
      end
      oslevel = oslevel.split('-')

      os_level = SpLevel.new(oslevel[0][0], oslevel[0][1], oslevel[1], oslevel[2])
      current_os_level = SpLevel.new(current_oslevel[0][0], current_oslevel[0][1], current_oslevel[1], current_oslevel[2])

      if !current_os_level.same_release?(os_level)
        Chef::Log.warn("Machine #{m} has different release than #{oslevel.join('-')}")
        next
      elsif current_os_level >= os_level
        Chef::Log.warn("Machine #{m} is already at same or higher level than #{oslevel.join('-')}")
        next
      else
        Chef::Log.info("Machine #{m} needs upgrade from #{current_oslevel.join('-')} to #{oslevel.join('-')}")
      end

      converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{new_lpp_source}\'") do
        nim.perform_sync_customization(new_lpp_source, m)
      end
    end
  end
end

##############################
# ACTION: master_setup
##############################
action :master_setup do
  # Example of nim_master_setup
  # nim_master_setup -a mk_resource=no -B -a device=/mnt
  unless new_resource.device.nil? || new_resource.device.empty?
    nim_master_setup_s = 'nim_master_setup -B -a mk_resource=no -a device=' + new_resource.device

    # converge here
    converge_by("nim: setup master \"#{nim_master_setup_s}\"") do
      nim = Mixlib::ShellOut.new(nim_master_setup_s)
      nim.valid_exit_codes = 0
      nim.run_command
      nim.error!
      nim.error?
    end
  end
end

##############################
# ACTION: check
##############################
action :check do
  check_nim_info(node)

  # build hash table
  nodes = Hash.new { |h, k| h[k] = {} }
  nodes['machine'] = node['nim']['clients'].keys
  nodes['oslevel'] = node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
  nodes['Cstate'] = node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }

  # converge here
  so = print_hash_by_columns(nodes)
  converge_by("check update status:\n#{so}") do
  end
end

##############################
# ACTION: compare
##############################
action :compare do
  check_nim_info(node)

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  # run niminv command
  niminv_s = "niminv -o invcmp -a targets=#{target_list.join(',')} -a base=any"
  so = shell_out!(niminv_s).stdout

  # converge here
  converge_by("compare installation inventory:\n#{so}") do
  end
end

##############################
# ACTION: script
##############################
action :script do
  Chef::Log.debug("targets: #{new_resource.targets}")
  Chef::Log.debug("script: #{new_resource.script}")
  Chef::Log.debug("async: #{new_resource.async}")

  check_nim_info(node)

  local_async = new_resource.async == true ? 'yes' : 'no'

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  nim_s = "nim -o cust -a script=#{new_resource.script} -a async=#{local_async} #{target_list.join(' ')}"
  # converge here
  converge_by("nim: script customization operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: allocate
##############################
action :allocate do
  Chef::Log.debug("targets: #{new_resource.targets}")
  Chef::Log.debug("lpp_source: #{new_resource.lpp_source}")

  check_nim_info(node)

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  nim_s = "nim -o allocate -a lpp_source=#{new_resource.lpp_source} #{target_list.join(' ')}"
  # converge here
  converge_by("nim: allocate operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: deallocate
##############################
action :deallocate do
  Chef::Log.debug("targets: #{new_resource.targets}")
  Chef::Log.debug("lpp_source: #{new_resource.lpp_source}")

  check_nim_info(node)

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  nim_s = "nim -o deallocate -a lpp_source=#{new_resource.lpp_source} #{target_list.join(' ')}"
  # converge here
  converge_by("nim: deallocate operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: bos_inst
##############################
action :bos_inst do
  Chef::Log.debug("targets: #{new_resource.targets}")
  Chef::Log.debug("group: #{new_resource.group}")
  Chef::Log.debug("script: #{new_resource.script}")

  check_nim_info(node)

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  # script
  script_s = new_resource.script.empty? ? '' : "-a script=#{new_resource.script}"

  nim_s = "nim -o bos_inst -a source=mksysb -a group=#{new_resource.group} #{script_s} #{target_list.join(' ')}"
  # converge here
  converge_by("nim: bos_inst operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: define_script
##############################
action :define_script do
  Chef::Log.debug("resource: #{new_resource.resource}")
  Chef::Log.debug("location: #{new_resource.location}")

  nim_s = "nim -o define -t script -a location=#{new_resource.location} -a server=master #{new_resource.resource}"
  # converge here
  converge_by("nim: define operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: remove
##############################
action :remove do
  Chef::Log.debug("resource: #{new_resource.resource}")

  nim_s = "nim -o remove #{new_resource.resource}"
  # converge here
  converge_by("nim: remove operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: reset
##############################
action :reset do
  Chef::Log.debug("resource: #{new_resource.resource}")
  Chef::Log.debug("force: #{new_resource.force}")

  force_s = new_resource.force == true ? '-F' : ''
  Chef::Log.debug("force_s: #{force_s}")

  nim_s = "nim #{force_s} -o reset #{new_resource.resource}"
  # converge here
  converge_by("nim: reset operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end

##############################
# ACTION: reboot
##############################
action :reboot do
  Chef::Log.debug("targets: #{new_resource.targets}")

  check_nim_info(node)

  # build list of targets
  target_list = expand_targets(new_resource.targets, node['nim']['clients'].keys)
  Chef::Log.debug("target_list: #{target_list}")

  nim_s = "nim -o reboot #{target_list.join(' ')}"
  # converge here
  converge_by("nim: reboot operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.stdout.each_line { |line| Chef::Log.info("[STDOUT] #{line.chomp}") }
    nim.stderr.each_line { |line| Chef::Log.info("[STDERR] #{line.chomp}") }
    nim.error!
    nim.error?
  end
end
