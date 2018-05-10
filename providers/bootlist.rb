#
# Copyright:: 2015-2016, Alain Dejoux <adejoux@djouxtech.net>
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
  @current_resource = new_resource.class.new(@new_resource.name)

  so = shell_out!("bootlist -m #{@new_resource.mode} -o")

  # initialize variables
  @current_resource.devices([])
  @current_resource.device_options({})
  # initializing tunables attribute
  so.stdout.each_line do |line|
    (device, options) = line.split(' ', 2)
    unless @current_resource.devices.include? device
      @current_resource.devices << device
    end

    next if options.nil?
    # remove default blv option
    options.sub!(/blv=hd5\s*/, '')
    # special case to manage pathid
    if @current_resource.device_options.key?(device) && @current_resource.device_options[device].match(/pathid/)
      new_pathid = options.match(/pathid=(\d+)/)[1]
      @current_resource.device_options[device].sub!(/(pathid=\S+)/, "\\1,#{new_pathid}")
      next
    end

    @current_resource.device_options[device] = options.chomp
  end

  Chef::Log.debug("current devices: #{@current_resource.devices}")
  Chef::Log.debug("current device_options: #{@current_resource.device_options}")
end

def perform_bootlist
  # build the command line to execute
  cmd = "bootlist -m #{@new_resource.mode} "
  @new_resource.devices.each do |device|
    cmd << " #{device}"
    next if new_resource.device_options.nil? || @new_resource.device_options[device].nil?
    cmd << " #{@new_resource.device_options[device]}"
  end

  converge_by("bootlist: #{cmd}") do
    shell_out!(cmd)
  end
end

# update action
action :update do
  # for each device ...
  @new_resource.devices.each_with_index do |device, index|
    #
    # if anything in the bootlist is different(value, order), we change the bootlist
    #

    if @current_resource.devices.nil?
      Chef::Log.debug('No device in bootlist !')
      perform_bootlist
      break
    end

    if @current_resource.devices.length != @new_resource.devices.length
      Chef::Log.debug('Not same number of devices !')
      Chef::Log.debug(@current_resource.devices.length)
      Chef::Log.debug(@new_resource.devices.length)
      perform_bootlist
      break
    end

    # check if device already set in the bootlist in the same position
    if @current_resource.devices[index].nil? || @current_resource.devices[index] != device
      Chef::Log.debug('device not in the same order !')
      perform_bootlist
      break
    end

    # check if we have device options
    next unless @new_resource.device_options && @new_resource.device_options.key?(device)
    next unless @current_resource.device_options.nil? || @current_resource.device_options[device] != @new_resource.device_options[device]
    Chef::Log.debug('Not same device options !')
    perform_bootlist
    break
  end
end

action :invalidate do
  converge_by("invalidate bootlist in mode #{@new_resource.mode}") do
    cmd = "bootlist -m #{@new_resource.mode} -i "
    Chef::Log.debug("command: #{cmd}")
    shell_out!(cmd)
  end
end
