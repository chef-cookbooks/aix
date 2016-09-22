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

property :desc, String, name_property: true
property :lpp_source, String
property :targets, String

class OhaiNimPluginNotFound < StandardError
end

class InvalidLppSourceProperty < StandardError
end

load_current_value do
end

def expand_targets
  # get list of all NIM machines from Ohai
  begin
    all_machines=node.fetch('nim', {}).fetch('clients').keys
    Chef::Log.info("Ohai client machine's list is #{all_machines}")
  rescue Exception => e
    raise OhaiNimPluginNotFound, "SUMA-SUMA-SUMA cannot find nim info from Ohai output"
  end

  selected_machines=Array.new

  # compute list of machines based on targets property
  if property_is_set?(:targets)
    if !targets.empty?
      targets.split(',').each do |machine|
        if machine.match(/\*/)
          # expand wildcard
          machine.gsub!(/\*/,'.*?')
          all_machines.collect do |m|
            if m =~ /^#{machine}$/
              selected_machines.concat(m.split)
            end
          end
        else
          selected_machines.concat(machine.split)
        end
      end
      selected_machines=selected_machines.sort.uniq
    else
      selected_machines=all_machines.sort
      Chef::Log.warn("No targets specified, consider all nim standalone machines as targets")
    end
  else
    selected_machines=all_machines.sort
    Chef::Log.warn("No targets specified, consider all nim standalone machines as targets!")
  end
  Chef::Log.info("List of targets expanded to #{selected_machines}")
  selected_machines
end

def check_lpp_source_name (lpp_source)
  begin
    if node['nim']['lpp_sources'].fetch(lpp_source).eql?(lpp_source)
      Chef::Log.info("Found lpp source #{lpp_source}")
    end
  rescue Exception => e
    raise InvalidLppSourceProperty, "SUMA-SUMA-SUMA cannot find lpp_source \'#{lpp_source}\' from Ohai output"
  end
end

action :update do

  # inputs
  puts ""
  Chef::Log.info("desc=\"#{desc}\"")
  Chef::Log.info("lpp_source=#{lpp_source}")
  Chef::Log.info("targets=#{targets}")

  check_lpp_source_name(lpp_source)

  # build list of targets
  target_list=expand_targets
  Chef::Log.info("target_list: #{target_list}")

  # nim install
  nim_s="nim -o cust -a lpp_source=#{lpp_source} -a fixes=update_all #{target_list.join(' ')}"
  Chef::Log.info("NIM operation: #{nim_s}")
  converge_by("nim custom operation: \"#{nim_s}\"") do
    Chef::Log.info("Install fixes...")
    shell_out!(nim_s)
  end

end
