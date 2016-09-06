# Author:: J�r�me Hurstel (<jerome.hurstel@atos.ne>) & Laurent Gay (<laurent.gay@atos.net>)
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

property :desc, [String,nil], name_property: true
property :lpp_source, String
property :targets, String

load_current_value do

end

action :update do

  Chef::Log.info("desc=#{desc}")
  Chef::Log.info("lpp_source=#{lpp_source}")
  Chef::Log.info("targets=#{targets}")
  Chef::Log.info("node['nim']=#{node['nim']}")

  # find lowest ML level by comparing each machine's oslevel from ohai
  target_list=""
  if property_is_set?(:targets)
    targets.split(',').each do |machine|
      begin
        new_filter_ml=String.new(node.fetch('nim', {}).fetch('clients', {}).fetch(machine, {}).fetch('oslevel'))
        Chef::Log.info("Obtained ML level for machine #{machine}: #{new_filter_ml}")
        target_list+=machine
        target_list+=" "
      rescue Exception => e
        Chef::Log.info("No ML level for machine #{machine}")
      end
    end
  end
  if target_list.strip.length == 0
    raise "NIM-NIM-NIM no client targets specified!"
  else
    Chef::Log.info("client targets: #{target_list}")
  end

  lpp_source_exist=false
  begin
    current_location=node.fetch('nim', {}).fetch('lpp_sources', {}).fetch(lpp_source, {}).fetch("location")
    Chef::Log.info("Obtained lpp-source define for #{lpp_source}: #{current_location}")
    lpp_source_exist=true
  rescue Exception => e
    Chef::Log.info("No lpp-source define for #{lpp_source}")
  end

  if lpp_source_exist
    # nim install
    nim_s="nim -o cust -a lpp_source=#{lpp_source} #{target_list}"
    converge_by("nim custom operation: \"#{nim_s}\"") do
      Chef::Log.info("Install fixes...")
      shell_out!("#{nim_s}")
    end
  end

end
