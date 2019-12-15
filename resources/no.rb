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

property :tunables, Hash
property :set_default, [TrueClass, FalseClass], default: false

load_current_value do
  so = shell_out!('no -x')
  # loading the tunables
  all_no_tunables = {}
  # for each tunable build an hash
  # with key => value (where value is an hash)
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
    tunable_hash = {}
    tunable_hash['current'] = current_tunable[1]
    tunable_hash['default'] = current_tunable[2]
    tunable_hash['reboot'] = current_tunable[3]
    tunable_hash['min'] = current_tunable[4]
    tunable_hash['max'] = current_tunable[5]
    tunable_hash['unit'] = current_tunable[6]
    tunable_hash['type'] = current_tunable[7]
    # the dtunable tunable is not there for each tunable
    tunable_hash['dtunable'] = if !current_tunable[8].chomp.empty?
                                 current_tunable[8].chomp
                               else
                                 'none'
                               end
    # Chef::Log.debug("no: #{@current_resource.name}->#{current_tunable[0]} = #{tunable_hash}")
    all_no_tunables[current_tunable[0].to_sym] = tunable_hash
  end
  # set this hash to the current value attribute
  tunables all_no_tunables
end

# update action
action :update do
  # for each tunables ...
  new_resource.tunables.each do |tunable, value|
    # check if attribute exists for current device, if not raising error
    if current_resource.tunables.key?(tunable)
      Chef::Log.debug("no: setting tunable #{tunable} with value #{value}")
      # ... if this one is already set to the desired value do nothing
      current_resource_tunable = current_resource.tunables[tunable]['current']
      Chef::Log.debug("comparing current tunable #{tunable}=#{current_resource_tunable} to value #{value}")
      if current_resource_tunable == value
        Chef::Log.debug("no: tunable #{tunable} is already set to value #{value}")
      # ... if this one is not set to the desired value add it to the no command
      else
        converge_by("no: setting tunable #{tunable}=#{value}") do
          Chef::Log.debug("no: #{tunable} will be set to value #{value}")
          # the command will always begin with no
          string_shell_out = 'no '
          # setting -p if set_default is true
          string_shell_out = string_shell_out << '-p ' if new_resource.set_default
          string_shell_out = string_shell_out << " -o #{tunable}=#{value} "
          # if type is bosboot or reboot
          if current_resource.tunables[tunable]['type'] == 'R' || current_resource.tunables[tunable]['type'] == 'B'
            string_shell_out.sub! '-p', '-r'
          end
          # TODO: here if type == B do a bosboot. Did not find any tunables with B type not implementing this
          Chef::Log.debug("command: #{string_shell_out}")
          shell_out!(string_shell_out)
          # if the command fails raise and exception
        end
      end
    else
      raise "no: #{tunable} does not exist"
    end
  end
end

# reset action
action :reset do
  # for each tunables ...
  new_resource.tunables.each do |tunable, _value|
    # check if attribute exists for current device, if not raising error
    if current_resource.tunables.key?(tunable)
      converge_by("no: resetting tunable #{tunable}") do
        Chef::Log.debug("no: resetting tunable #{tunable}")
        # the command will always begin with no
        string_shell_out = 'no '
        # setting -p if set_default is true
        string_shell_out = string_shell_out << '-p ' if new_resource.set_default
        # append -d to set tunable to default
        string_shell_out = string_shell_out << "-d #{tunable}"
        # if type is bosboot or reboot or incremental
        if current_resource.tunables[tunable]['type'] == 'R' || current_resource.tunables[tunable]['type'] == 'B' || current_resource.tunables[tunable]['type'] == 'I'
          string_shell_out.sub! '-p', '-r'
        end
        # TODO: here if type == B do a bosboot. Did not find any tunables with B type not implementing this
        Chef::Log.debug("command: #{string_shell_out}")
        shell_out!(string_shell_out)
        # if the command fails raise and exception
        raise "#{string_shell_out} failed" if so.exitstatus != 0
      end
    else
      raise "no: #{tunable} does not exist"
    end
  end
end

action :reset_all do
  converge_by('no : resetting all') do
    string_shell_out = 'no -D'
    shell_out(string_shell_out)
  end
end

action :reset_all_with_reboot do
  converge_by('no : resetting all with reboot') do
    string_shell_out = 'yes | no -r -D '
    shell_out(string_shell_out)
  end
end
