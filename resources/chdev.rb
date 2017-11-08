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

property :attributes, Hash
# If both of these are specified, the resulting shellout command fails
property :need_reboot, [true, false], default: false
property :hot_change, [true, false], default: false

load_current_value do |desired|
  # does the device exists
  so = shell_out("lsattr -El #{desired.name}")
  Chef::Log.debug("command: #{so}")
  current_value_does_not_exist! if so.exitstatus != 0

  # loading the attributes
  all_device_attr = {}
  # for each attribute of the device build an hash
  # with key => value
  so.stdout.each_line do |line|
    line.chomp! # remove end of line character
    current_attr_a = line.split(' ')
    Chef::Log.debug("#{desired.name}->#{current_attr_a[0]} = #{current_attr_a[1]}")
    all_device_attr[current_attr_a[0].to_sym] = current_attr_a[1]
  end

  # set this hash to the current resource attribute
  attributes all_device_attr
  Chef::Log.debug("current attributes: #{all_device_attr}")
end

# update action
action :update do
  set_attr = false
  # the command will always begin with chdev -l
  string_shell_out = 'chdev -l ' << current_value.name
  # for each attributes ...
  Chef::Log.debug(new_resource.attributes)
  new_resource.attributes.each do |attribute, value|
    # force string or else string comparison below does not work on integers
    value = value.to_s
    # check if attribute exists for current device, if not raising error
    if current_value.attributes.key?(attribute)
      Chef::Log.debug("chdev #{current_value.name} attribute #{attribute} with value #{value}")
      # ... if this one is already set to the desired value do nothing
      current_resource_attr = current_value.attributes[attribute]
      Chef::Log.debug("comparing current resource #{attribute}=#{current_resource_attr} to value #{value}")
      if current_resource_attr == value
        Chef::Log.debug("chdev: device #{current_value.name}.attribute is already set to value #{value}")
      # ... if this one is not set to the desired value add it to the chdev command
      else
        set_attr = true
        Chef::Log.warn("chdev: device #{current_value.name}.attribute will be set to value #{value} (previously #{current_resource_attr})")
        string_shell_out = string_shell_out << " -a #{attribute}=#{value}"
      end
    else
      raise "chdev device #{current_value.name} has not attribute #{attribute}"
    end
  end
  # if both -P and -U will be add raise an error (-P or -U not both)
  if new_resource.need_reboot && new_resource.hot_change
    raise 'chdev: conflicting flags: -P -U'
  end
  # if attributes needs a reboot add -P (for permanent to the command)
  string_shell_out = string_shell_out << ' -P' if new_resource.need_reboot
  # if device attribute can be change while available add -U (for True+ attr)
  string_shell_out = string_shell_out << ' -U' if new_resource.hot_change
  if set_attr
    converge_by("chdev device #{new_resource.name} with #{new_resource.attributes}") do
      Chef::Log.warn("command: #{string_shell_out}")
      shell_out!(string_shell_out)
    end
  end
end
