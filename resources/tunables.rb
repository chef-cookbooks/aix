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

property :mode, Symbol, equal_to: %i[ioo vmo schedo no], identity: true, required: true, desired_state: false
property :tunables, Hash
property :permanent, [true, false], default: false
property :nextboot, [true, false], default: false

load_current_value do |desired|
  # when property has "identity: true", it's available like this in the
  # load_current_value block (also need do |desired| above).
  cmd = desired.mode
  so = shell_out!("#{cmd} -x")

  # initializing tunables attribute
  all_tunables = {}
  so.stdout.each_line do |line|
    # info:tunable,current,default,reboot,min,max,unit,type,{dtunable }
    # current = current value
    # default = default value
    # reboot = reboot value
    # min = minimal value
    # max = maximum value
    # unit = tunable unit of measure
    # type = parameter type:
    #  * D (for Dynamic),
    #  * S (for Static),
    #  * R (for Reboot),
    #  * B (for Bosboot),
    #  * M (for Mount),
    #  * I (for Incremental),
    #  * C (for Connect),
    #  * d (for Deprecated)
    #  * dtunable = space separated list of dependent tunable parameters
    # no output is separted with ','
    current_tunable = line.split(',')
    all_tunables[current_tunable[0].to_sym] = {
      current: current_tunable[1],
      default: current_tunable[2],
      reboot: current_tunable[3],
      min: current_tunable[4],
      max: current_tunable[5],
      unit: current_tunable[6],
      type: current_tunable[7],
      dtunable: current_tunable[8] || 'none',
    }
  end
  # set this hash to the current value attribute
  tunables all_tunables
end

# update action
action :update do
  cmd = new_resource.mode
  # for each tunables ...
  new_resource.tunables.each do |tunable, value|
    # raise error if tunable doesn't exist
    unless current_value.tunables.key?(tunable.to_sym)
      raise "#{cmd}: #{tunable} does not exist"
    end

    Chef::Log.debug("#{cmd}: setting tunable #{tunable} with value #{value}")
    # next if value already set
    if current_value.tunables[tunable.to_sym][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to value #{value}")
    else
      Chef::Log.debug("#{cmd}: #{tunable} will be set to value #{value}")
      converge_by("#{cmd}: setting tunable #{tunable}=#{value}") do
        Chef::Log.debug("#{cmd}: #{tunable} will be set to value #{value}")
        # the command will always begin with no
        string_shell_out = "#{cmd} "
        # setting -p if set_default is true
        string_shell_out = string_shell_out << '-p ' if new_resource.permanent
        string_shell_out = string_shell_out << "-o #{tunable}=#{value}"
        # if type is bosboot or reboot
        if current_value.tunables[tunable]['type'] == 'R' || current_value.tunables[tunable]['type'] == 'B'
          string_shell_out.sub! '-p', '-r'
        end
        # TODO: here if type == B do a bosboot. Did not find any tunables with B type not implementing this
        Chef::Log.debug("command: #{string_shell_out}")
        shell_out!(string_shell_out)
        # if the command fails raise and exception
      end
    end
  end
end

# reset action
action :reset do
  cmd = new_resource.mode
  # for each tunables ...
  Chef::Log.debug(new_resource.tunables)
  new_resource.tunables.each do |tunable, value|
    # raise error if tunable doesn't exist
    unless current_value.tunables.key?(tunable.to_sym)
      raise "#{cmd}: #{tunable} does not exist"
    end

    if current_value.tunables[tunable.to_sym][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to default value #{value}")
    else
      Chef::Log.debug("#{cmd}: resetting tunable #{tunable}")
      converge_by("#{cmd}: resetting tunable #{tunable}") do
        # the command will always begin with #{cmd}
        string_shell_out = "#{cmd} "
        # setting -p if set_default is true
        string_shell_out = string_shell_out << '-p ' if new_resource.permanent
        # append -d to set tunable to default
        string_shell_out = string_shell_out << "-d #{tunable}"
        # if type is bosboot or reboot or incremental
        if current_value.tunables[tunable]['type'] == 'R' || current_value.tunables[tunable]['type'] == 'B' || current_value.tunables[tunable]['type'] == 'I'
          string_shell_out.sub! '-p', '-r'
        end
        # TODO: here if type == B do a bosboot. Did not find any tunables with B type not implementing this
        Chef::Log.debug("command: #{string_shell_out}")
        shell_out!(string_shell_out)
        # if the command fails raise and exception
        raise "#{string_shell_out} failed" if so.exitstatus != 0
      end
    end
  end
end

action :reset_all do
  cmd = new_resource.mode
  converge_by("#{cmd} : resetting all") do
    string_shell_out = "#{cmd} -D"
    string_shell_out = "yes | #{cmd} -r -D" if new_resource.nextboot
    shell_out(string_shell_out)
  end
end
