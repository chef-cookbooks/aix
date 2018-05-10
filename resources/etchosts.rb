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

# When modifying /etc/hosts, the hostent command treats hostnames and aliases as equivelent
property :ip_address, String
property :new_hostname, String
property :aliases, Array, default: []

load_current_value do |desired|
  hostent = shell_out("hostent -s #{desired.name}")
  Chef::Log.debug("command: #{hostent}")
  current_value_does_not_exist! if hostent.exitstatus != 0
  Chef::Log.debug("etchosts: current resource: #{hostent}")

  # TODO: hostent can return multiple IPs and names.
  hostent_array = hostent.stdout.split(' ')
  ip_address hostent_array.shift
  aliases hostent_array
end

# add
action :add do
  unless current_resource
    # dup array so it can be modified
    hostnames_a = new_resource.aliases.dup

    # if IP address not explicitly defined, assume it's the resource name
    if new_resource.ip_address.nil?
      ip = new_resource.name
    else
      ip = new_resource.ip_address
      # prepend resource name to array of aliases
      hostnames_a.unshift(new_resource.name)
    end

    hostnames_s = hostnames_a.join(' ')
    hostent_add_s = "hostent -a #{ip} -h \"#{hostnames_s}\""
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

    # Initialize hostent command.
    # It is keyed off of the IP existing in /etc/hosts from load_current_value
    hostent_change_s = "hostent -c #{current_value.ip_address} -h \""

    # dup array so it can be modified
    hostnames_a = new_resource.aliases.dup

    # If new_resource.new_hostname is defined, pre-pend new_hostname to hostnames/aliases
    hostnames_a.unshift(new_resource.new_hostname) unless new_resource.new_hostname.nil?

    # join hostnames so they can be easily compared and used in command string
    aliases_current_s = current_value.aliases.join(' ')
    aliases_new_s = hostnames_a.join(' ')

    # Check if IP address is changing
    if !new_resource.ip_address.nil? && new_resource.ip_address != current_value.ip_address
      if property_is_set?(:ip_address)
        hostent_change_s << aliases_current_s
        hostent_change_s << '"'
        hostent_change_s << " -i #{new_resource.ip_address}"
        change = true
      end
    else
      # Hostnames/aliases are changing
      hostent_change_s << aliases_new_s
      hostent_change_s << '"'
      change = true if aliases_current_s != aliases_new_s
    end

    # If IP or hostnames changed, converge
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
  so = shell_out('hostent -S >/dev/null')
  if so.exitstatus == 0
    hostent_del_all_s = 'hostent -X'
    converge_by('etchost: removing all entries') do
      Chef::Log.warn("etchosts: running #{hostent_del_all_s}")
      shell_out!(hostent_del_all_s)
    end
  end
end
