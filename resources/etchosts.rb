#
# Copyright:: 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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
#

property :ip_address, String
property :new_hostname, String
property :aliases, Array

load_current_value do |desired|
  # hostent = shell_out("hostent -s #{desired.name}", returns: [0, 1])
  hostent = shell_out("hostent -s #{desired.name}")
  Chef::Log.debug("command: #{hostent}")
  current_value_does_not_exist! if hostent.exitstatus != 0

  # if resource exists loads its attributes
  Chef::Log.debug('etchosts: resource exists loading attributes')
  hostent_array = hostent.stdout.split(' ')
  Chef::Log.debug("etchosts: current resource ip address: #{hostent_array[0]}")
  ip_address hostent_array[0]
  name hostent_array[1]
  Chef::Log.debug("etchosts: current resource name: #{hostent_array[1]}")
  # Initialize array for current aliases
  current_aliases = []
  # filling the array with the aliases if there are aliases
  if hostent_array.length > 2
    (2..hostent_array.length - 1).each do |i|
      Chef::Log.debug("etchosts: current adding alias: #{hostent_array[i]}")
      current_aliases.push(hostent_array[i])
    end
  end
  Chef::Log.debug("etchosts: current resource aliases : #{current_aliases}")
  aliases current_aliases
end

# add
action :add do
  unless current_resource
    hostent_add_s = "hostent -a #{new_resource.ip_address} -h \"#{new_resource.name}"
    # add aliases if there are aliases
    if new_resource.aliases.nil?
      # no aliases, closing the command line
      hostent_add_s = hostent_add_s << '"'
    else
      # add each aliases to the command line
      (0..new_resource.aliases.length - 1).each do |i|
        hostent_add_s = hostent_add_s << " #{new_resource.aliases[i]}"
      end
      # close last double quote
      hostent_add_s = hostent_add_s << '"'
    end
    # TODO: There isn't anything here to add aliases after the first name exists
    converge_by("hostent: add #{new_resource.name} in /etc/hosts file") do
      Chef::Log.debug("etchosts: running #{hostent_add_s}")
      shell_out!(hostent_add_s)
    end
  end
end

# delete
action :delete do
  if current_resource
    hostent_del_s = "hostent -d #{current_value.ip_address}"
    converge_by("hostent: delete #{current_value.ip_address}") do
      Chef::Log.warn("etchosts: running #{hostent_del_s}")
      shell_out!(hostent_del_s)
    end
  end
end

# change
action :change do
  if current_resource
    change = false
    hostent_change_s = "hostent -c #{current_value.ip_address} "
    # if new_hostname attribute exists, we need to change hostname
    # CASE1 hostname is changing
    if !new_resource.new_hostname.nil?
      if new_resource.new_hostname != current_value.name
        change = true
        hostent_change_s = hostent_change_s << "-h \"#{new_resource.new_hostname} "
        # CASE2 hostname and aliases are changing
        unless new_resource.aliases.nil?
          # add each aliases to the command line
          (0..new_resource.aliases.length - 1).each do |i|
            hostent_change_s = hostent_change_s << " #{new_resource.aliases[i]}"
          end
        end
        # close last double quote
        hostent_change_s = hostent_change_s << '" '
      end
    else
      hostent_change_s = hostent_change_s << "-h \"#{new_resource.name}\" "
    end
    # CASE3 ip is changing
    # if ip_address are different change them
    unless new_resource.ip_address.nil?
      if new_resource.ip_address != current_value.ip_address
        # CASE4 ip and aliases are changing
        unless new_resource.aliases.nil?
          hostent_change_s = hostent_change_s << "-h \"#{current_value.name} "
          unless new_resource.aliases.nil?
            # add each aliases to the command line
            (0..new_resource.aliases.length - 1).each do |i|
              hostent_change_s = hostent_change_s << " #{new_resource.aliases[i]}"
            end
          end
          # close last double quote
          hostent_change_s = hostent_change_s << '" '
        end
        change = true
        if property_is_set?(:ip_address)
          hostent_change_s = hostent_change_s << "-i #{new_resource.ip_address}"
        end
      end
    end
    # TODO: There isn't anything here to handle if aliases change
    if change
      converge_by("etchost: modifying #{new_resource.name} in /etc/hosts") do
        Chef::Log.debug("etchosts: running #{hostent_change_s}")
        shell_out!(hostent_change_s)
      end
    end
  end
end

# delete_all
action :delete_all do
  hostent_del_all_s = 'hostent -X'
  converge_by('etchost: removing all entries') do
    Chef::Log.debug("etchosts: running #{hostent_del_all_s}")
    shell_out!(hostent_del_all_s)
  end
end
