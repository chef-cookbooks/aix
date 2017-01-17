#
# Copyright 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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

use_inline_resources

# support whyrun
def whyrun_supported?
  true
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixChdev.new(@new_resource.name)
  @current_resource.exists = false

  # does the device exists
  so = shell_out("lsattr -El #{@current_resource.name}")
  Chef::Log.debug("command: #{so}")
  if so.exitstatus.zero?
    @current_resource.exists = true
  else
    @current_resource.exists = false
    raise("device #{@current_resource.name} does not exists")
  end

  # loading the attributes
  all_device_attr = {}
  if @current_resource.exists
    # for each attribute of the device build an hash
    # with key => value
    so.stdout.each_line do |line|
      current_attr_a = line.split(' ')
      Chef::Log.debug("#{@current_resource.name}->#{current_attr_a[0]} = #{current_attr_a[1]}")
      all_device_attr[current_attr_a[0].to_sym] = current_attr_a[1]
    end
    # set this hash to the current resource attribute
    @current_resource.attributes(all_device_attr)
    Chef::Log.debug("current attributes: #{@current_resource.attributes(all_device_attr)}")
  end
end

# update action
action :update do
  if !@current_resource.exists
    Chef::Log.debug("chdev: device #{@current_resource.name} does not exists")
    raise "chdev: device #{@current_resource.name} does not exists"
  else
    set_attr = false
    # the command will always begin with chdev -l
    string_shell_out = 'chdev -l ' << @current_resource.name
    # for each attributes ...
    Chef::Log.debug(@new_resource.attributes)
    @new_resource.attributes.each do |attribute, value|
      # check if attribute exists for current device, if not raising error
      if @current_resource.attributes.key?(attribute)
        Chef::Log.debug("chdev #{@current_resource.name} attribute #{attribute} with value #{value}")
        # ... if this one is already set to the desired value do nothing
        current_resource_attr = @current_resource.attributes[attribute]
        Chef::Log.debug("comparing current resource #{attribute}=#{current_resource_attr} to value #{value}")
        if current_resource_attr == value
          Chef::Log.debug("chdev: device #{@current_resource.name}.attribute is already set to value #{value}")
        # ... if this one is not set to the desired value add it to the chdev command
        else
          set_attr = true
          Chef::Log.debug("chdev: device #{@current_resource.name}.attribute will be set to value #{value}")
          string_shell_out = string_shell_out << " -a #{attribute}=#{value}"
        end
      else
        raise "chdev device #{@current_resource.name} has not attribute #{attribute}"
      end
    end
    # if both -P and -U will be add raise an error (-P or -U not both)
    if @new_resource.need_reboot && @new_resource.hot_change
      raise 'chdev: conflicting flags: -P -U'
    end
    # if attributes needs a reboot add -P (for permanent to the command)
    string_shell_out = string_shell_out << ' -P' if @new_resource.need_reboot
    # if device attribute can be change while available add -U (for True+ attr)
    string_shell_out = string_shell_out << ' -U' if @new_resource.hot_change
    if set_attr
      converge_by("chdev device #{@new_resource.name} with #{@new_resource.attributes}") do
        Chef::Log.debug("command: #{string_shell_out}")
        shell_out!(string_shell_out)
      end
    end
  end
end
