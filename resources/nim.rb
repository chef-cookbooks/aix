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

property :desc, String, name_property: true
property :lpp_source, String, required: true
property :targets, String, required: true
property :async, [true, false], default: false

default_action :update

load_current_value do
end

action :update do
  # inputs
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("lpp_source=#{lpp_source}")
  Chef::Log.debug("targets=#{targets}")

  check_ohai

  # force latest_sp/tl synchronously
  async = false if lpp_source == 'latest_tl' || lpp_source == 'latest_sp'

  # build list of targets
  target_list = expand_targets
  Chef::Log.debug("target_list: #{target_list}")

  # nim install
  nim = Nim.new
  if async
    # get targetted oslevel
    os_level = check_lpp_source_name(lpp_source)
    Chef::Log.debug("os_level: #{os_level}")

    converge_by("nim: perform asynchronous software customization for client(s) \'#{target_list.join(' ')}\' with resource \'#{lpp_source}\'") do
      nim.perform_customization(lpp_source, target_list.join(' '), async)
    end
  else # synchronous update
    target_list.each do |m|
      if lpp_source == 'latest_tl' || lpp_source == 'latest_sp'
        lpp_source_array = lpp_source.split('_')
        time = lpp_source_array[0]
        type = lpp_source_array[1]
        new_lpp_source = find_resource_by_client(type, time, m)
        Chef::Log.debug("new_lpp_source: #{new_lpp_source}")
      else
        check_lpp_source_name(lpp_source)
        new_lpp_source = lpp_source
      end

      # extract oslevel from lpp source
      os_level = new_lpp_source.to_s.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})-lpp_source$/)[1]
      Chef::Log.debug("os_level: #{os_level}")

      # get current oslevel
      current_os_level = node['nim']['clients'][m]['oslevel']
      Chef::Log.debug("current_os_level: #{current_os_level}")

      if OsLevel.new(current_os_level) >= OsLevel.new(os_level)
        Chef::Log.warn("Machine #{m} is already at same or higher level than #{os_level}")
      else
        converge_by("nim: perform synchronous software customization for client \'#{m}\' with resource \'#{new_lpp_source}\'") do
          nim.perform_customization(new_lpp_source, m, async)
        end
      end
    end
  end
end

action :master_setup do
  # Example of nim_master_setup
  # nim_master_setup -a mk_resource=no -B -a device=/mnt
  nim_master_setup_s = 'nim_master_setup -B -a mk_resource=no'

  unless mount_point.nil?
    nim_master_setup_s = nim_master_setup_s << ' -a device=' << mount_point
  end

  # converge here
  converge_by("nim: setup master \"#{nim_master_setup_s}\"") do
    nim = Mixlib::ShellOut.new(nim_master_setup_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.error!
    nim.error?
  end
end

action :check do
  check_ohai
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

action :compare do
  check_ohai
  # build list of targets
  target_list = expand_targets
  Chef::Log.debug("target_list: #{target_list}")
  # run niminv command
  niminv_s = "niminv -o invcmp -a targets=#{target_list.join(',')} -a base=any"
  so = shell_out!(niminv_s).stdout
  # converge here
  converge_by("compare installation inventory:\n#{so}") do
  end
end

action :allocate do
  Chef::Log.debug("target: #{target}")
  Chef::Log.debug("lpp_source: #{lpp_source}")
  nim_s = "nim -o allocate -a lpp_source=#{lpp_source} #{target}"
  # converge here
  converge_by("nim: allocate operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.error!
    nim.error?
  end
end

action :deallocate do
  Chef::Log.debug("target: #{target}")
  Chef::Log.debug("lpp_source: #{lpp_source}")
  nim_s = "nim -o deallocate -a lpp_source=#{lpp_source} #{target}"
  # converge here
  converge_by("nim: deallocate operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.error!
    nim.error?
  end
end

action :bos_inst do
  group = "#{lpp_source.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2})-[0-9]{4}-lpp_source$/)[1]}_resources"
  nim_s = "nim -o bos_inst -a source=mksysb -a group=#{group} -a target=#{targets.split(/[,\s]/)}"
  # converge here
  converge_by("nim: bos_inst operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.error!
    nim.error?
  end
end
