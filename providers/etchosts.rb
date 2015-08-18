# Author:: Benoit Creau (<benoit.creau@chmod666.org>)
# Cookbook Name:: aix
# Provider:: etchosts
#
# Copyright:: 2015, Benoit Creau
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
require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# loading current resource 
def load_current_resource
  @current_resource = Chef::Resource::AixEtchosts.new(@new_resource.name)
  
  # we say by default that the entry is no in the /etc/hosts file 
  @current_resource.exists = false

  hostent = Mixlib::ShellOut.new("hostent -s #{@new_resource.name}")
  hostent.valid_exit_codes = 0
  hostent.run_command
  if !hostent.error? 
    Chef::Log.debug("etchosts: resource exists")
    @current_resource.exists = true
  else
    Chef::Log.debug("etchosts: resource does not exists")
  end

  # if resource exists loads its attributes
  if @current_resource.exists
    Chef::Log.debug("etchosts: resource exists loading attributes")
    hostent_array = hostent.stdout.split(" ") 
    Chef::Log.debug("etchosts: current resource ip address: #{hostent_array[0]}")
    @current_resource.ip_address(hostent_array[0])
    @current_resource.name(hostent_array[1])
    Chef::Log.debug("etchosts: current resource name: #{hostent_array[1]}")
    # filling the array with the aliases if there are aliases
    if !@current_resource.aliases.nil?
      (2 .. hostent_array.length).each do |i|
        Chef::Log.debug("etchosts: current adding alias: #{hostent_array[i]}")
        @current_resource.aliases.push(hostent_array[i])
      end
    end
    Chef::Log.debug("etchosts: current resource aliases : @current_resource.aliases")
  end
end

# add 
action :add do
  if !@current_resource.exists
    hostent_add_s="hostent -a #{@new_resource.ip_address} -h \"#{@new_resource.name}"
    # add aliases if there are aliases
    if @new_resource.aliases.nil?
      # no aliases, closing the command line
      hostent_add_s = hostent_add_s << "\""
    else
      # add each aliases to the command line
      (0 .. @new_resource.aliases.length).each do |i|
        hostent_add_s = hostent_add_s << " #{@new_resource.aliases[i]}"
      end
      # close last double quote
      hostent_add_s = hostent_add_s << "\""
    end
    converge_by("hostent: add #{@new_resource.name} in /etc/hosts file") do
      Chef::Log.debug("etchosts: running #{hostent_add_s}")
      hostent_add = Mixlib::ShellOut.new(hostent_add_s)
      hostent_add.valid_exit_codes = 0
      hostent_add.run_command
      hostent_add.error!
      hostent_add.error?
    end
  end
end

# delete
action :delete do
  if @current_resource.exists
    hostent_del_s="hostent -d #{@new_resource.ip_address}"
    converge_by("hostent: delete #{@new_resource.ip_address}") do
      Chef::Log.debug("etchosts: running #{hostent_del_s}")
      hostent_del = Mixlib::ShellOut.new(hostent_del_s)
      hostent_del.valid_exit_codes = 0
      hostent_del.run_command
      hostent_del.error!
      hostent_del.error?
    end
  end
end

# change
action :change do
  if @current_resource.exists
    change = false
    hostent_change_s="hostent -c #{@current_resource.ip_address} "
    # if new_hostname attribute exists, we need to change hostname
    # CASE1 hostname is changing
    if !@new_resource.new_hostname.nil?
      if "#{@new_resource.new_hostname}" != "#{@current_resource.name}"
        change = true
        hostent_change_s = hostent_change_s << "-h \"#{@new_resource.new_hostname} "
        # CASE2 hostname and aliases are changing
        if !@new_resource.aliases.nil?
          # add each aliases to the command line
          (0 .. @new_resource.aliases.length).each do |i|
            hostent_change_s = hostent_change_s << " #{@new_resource.aliases[i]}"
          end
        end
        # close last double quote
        hostent_change_s = hostent_change_s << "\" "
      end
    else
        hostent_change_s = hostent_change_s << "-h \"#{@new_resource.name}\" "
    end
    # CASE3 ip is changing
    # if ip_address are different change them
    if !@new_resource.ip_address.nil?
      if "#{@new_resource.ip_address}" != "#{@current_resource.ip_address}"
        # CASE4 ip and aliases are changing
        if !@new_resource.aliases.nil?
          hostent_change_s = hostent_change_s << "-h \"#{@current_resource.name} "
          if !@new_resource.aliases.nil?
            # add each aliases to the command line
            (0 .. @new_resource.aliases.length).each do |i|
              hostent_change_s = hostent_change_s << " #{@new_resource.aliases[i]}"
            end
          end
          # close last double quote
          hostent_change_s = hostent_change_s << "\" "
        end
        change = true
        hostent_change_s = hostent_change_s << "-i #{@new_resource.ip_address}"
      end
    end
    if change
      converge_by("etchost: modifying #{@new_resource.name} in /etc/hosts") do
        Chef::Log.debug("etchosts: running #{hostent_change_s}")
        hostent_change = Mixlib::ShellOut.new(hostent_change_s)
        hostent_change.valid_exit_codes = 0
        hostent_change.run_command
        hostent_change.error!
        hostent_change.error?
      end
    end
  end
end

# delete_all
action :delete_all do
  hostent_del_all_s = "hostent -X"
  converge_by("etchost: removing all entries") do
    Chef::Log.debug("etchosts: running #{hostent_del_all_s}")
    hostent_del_all = Mixlib::ShellOut.new(hostent_del_all_s)
    hostent_del_all.valid_exit_codes = 0
    hostent_del_all.run_command
    hostent_del_all.error!
    hostent_del_all.error?
  end
end
