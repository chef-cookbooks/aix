# Author:: IBM Corporation
# Cookbook Name:: aix
# Provider:: nim
#
# Copyright:: 2016, Atos
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

property :desc, String, name_property: true
property :lpp_source, String
property :targets, String
property :async, [true, false], default: false

load_current_value do
end

action :update do

  # inputs
  puts ""
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("lpp_source=#{lpp_source}")
  Chef::Log.debug("targets=#{targets}")

  check_ohai

  # get targetted oslevel
  os_level=check_lpp_source_name(lpp_source)
  Chef::Log.debug("os_level: #{os_level}")

  # build list of targets
  target_list=expand_targets
  Chef::Log.debug("target_list: #{target_list}")

  # nim install
  if async
    str=target_list.join(' ')
    nim_s="nim -o cust -a lpp_source=#{lpp_source} -a accept_licenses=yes -a fixes=update_all -a async=yes #{str}"
    Chef::Log.warn("Start updating machines \'#{str}\' to #{lpp_source}.")
    converge_by("nim custom operation: \"#{nim_s}\"") do
      so=shell_out!(nim_s, timeout: 3000)
      if so.error?
        unless so.stdout =~ /Either the software is already at the same level as on the media, or/m
          raise NimCustError, "Error: cannot update"
        end
      end 
    end
  else
    target_list.each do |m|
	  current_os_level=node['nim']['clients'][m]['oslevel']
	  if OsLevel.new(current_os_level) >= OsLevel.new(os_level)
        Chef::Log.warn("Machine #{m} is already at same or higher level than #{os_level}")
      else
        nim_s="nim -o cust -a lpp_source=#{lpp_source} -a accept_licenses=yes -a fixes=update_all #{m}"
        Chef::Log.warn("Start updating machine #{m} from #{current_os_level} to #{lpp_source}.")
        converge_by("nim custom operation: \"#{nim_s}\"") do
	      do_not_error=false
	      exit_status=Open3.popen3(nim_s) do |stdin, stdout, stderr, wait_thr|
            stdin.close
            stdout.each_line do |line|
              if line =~ /^Filesets processed:.*?[0-9]+ of [0-9]+/
                print "\r#{line.chomp}"
              elsif line =~ /^Finished processing all filesets./
                print "\r#{line.chomp}"
              end
            end
            puts ""
            stdout.close
            stderr.each_line do |line|
              if line =~ /Either the software is already at the same level as on the media, or/
                do_not_error=true
		      end
		      puts line
            end
            stderr.close
            wait_thr.value # Process::Status object returned.
          end
          Chef::Log.warn("Finish updating #{m}.")
          unless exit_status.success? or do_not_error
            raise NimCustError, "Error: cannot update machine #{m}"
          end
        end
      end
    end
  end

end

action :master_setup do
  # Example of nim_master_setup
  # nim_master_setup -a mk_resource=no -B -a device=/mnt
  nim_master_setup_s="nim_master_setup -B -a mk_resource=no"

  unless mount_point.nil?
    nimmster_setup_s = nim_master_setup_s << ' -a device=' << mount_point
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
  nodes=Hash.new{ |h,k| h[k] = {} }
  nodes['machine']=node['nim']['clients'].keys
  nodes['oslevel']=node['nim']['clients'].values.collect { |m| m.fetch('oslevel', nil) }
  nodes['Cstate']=node['nim']['clients'].values.collect { |m| m.fetch('lsnim', {}).fetch('Cstate', nil) }
  # converge here
  so=print_hash_by_columns(nodes)
  converge_by("check update status:\n#{so}") do
  end
end

action :compare do
  check_ohai
  # build list of targets
  target_list=expand_targets
  Chef::Log.debug("target_list: #{target_list}")
  # run niminv command
  niminv_s="niminv -o invcmp -a targets=#{target_list.join(',')} -a base=any"
  so=shell_out!(niminv_s).stdout
  # converge here
  converge_by("compare installation inventory:\n#{so}") do
  end
end

action :allocate do
  Chef::Log.debug("target: #{target}")
  Chef::Log.debug("lpp_source: #{lpp_source}")
  nim_s="nim -o allocate -a lpp_source=#{lpp_source} #{target}"
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
  nim_s="nim -o deallocate -a lpp_source=#{lpp_source} #{target}"
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
  group="#{lpp_source.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2})-[0-9]{4}-lpp_source$/)[1]}_resources"
  nim_s="nim -o bos_inst -a source=mksysb -a group=#{group} -a target=#{targets.split(/[,\s]/)}"
  # converge here
  converge_by("nim: bos_inst operation \"#{nim_s}\"") do
    nim = Mixlib::ShellOut.new(nim_s)
    nim.valid_exit_codes = 0
    nim.run_command
    nim.error!
    nim.error?
  end
end
