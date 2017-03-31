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
  @current_resource = Chef::Resource::AixTunables.new(@new_resource.name)

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
  @current_resource.tunables(all_tunables)
  Chef::Log.debug(@current_resource.tunables)
end

# update action
action :update do
  # for each tunables ...
  Chef::Log.debug(@new_resource.tunables)
  @new_resource.tunables.each do |tunable, value|
    # raise error if tunable doesn't exist
    unless @current_resource.tunables.key?(tunable.to_sym)
      raise "#{cmd}: #{tunable} does not exist"
    end

    Chef::Log.debug("#{cmd}: setting tunable #{tunable} with value #{value}")
    # next if value already set
    if @current_resource.tunables[tunable.to_sym][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to value #{value}")
    else
      Chef::Log.debug("#{cmd}: #{tunable} will be set to value #{value}")
      converge_by("#{cmd}: setting tunable #{tunable}=#{value}") do
        string_shell_out = gen_shell_out params: "-o #{tunable}=#{value} ", tunable: tunable.to_sym
        Chef::Log.debug("command: #{string_shell_out}")
        shell_out!(string_shell_out)
      end
    end
  end
end

# reset action
action :reset do
  # for each tunables ...
  Chef::Log.debug(@new_resource.tunables)
  @new_resource.tunables.each do |tunable, value|
    # raise error if tunable doesn't exist
    unless @current_resource.tunables.key?(tunable.to_sym)
      raise "#{cmd}: #{tunable} does not exist"
    end

    if @current_resource.tunables[tunable.to_sym][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to default value #{value}")
    else
      Chef::Log.debug("#{cmd}: reseting tunable #{tunable}")
      converge_by("#{cmd}: reseting tunable #{tunable}") do
        string_shell_out = gen_shell_out params: " -d #{tunable}", tunable: tunable.to_sym
        Chef::Log.debug("command: #{string_shell_out}")
        so = shell_out(string_shell_out)
        # if the command fails raise and exception
        raise "#{cmd}: #{string_shell_out} failed" if so.exitstatus != 0
      end
    end
  end
end

action :reset_all do
  converge_by("#{cmd} : resetting all") do
    string_shell_out = "#{cmd} -D"
    string_shell_out = "yes | #{cmd} -r -D" if @new_resource.nextboot
    shell_out(string_shell_out)
  end
end

private

# get command name
# @api private
def cmd
  @new_resource.mode.to_s
end

# generate command line
# @api private
def gen_shell_out(params: nil, tunable: nil)
  params = " -p #{params}" if @new_resource.permanent
  if tunable && %w(R B I).include?(@current_resource.tunables[tunable][:type])
    params.sub! '-p', '-r'
  end
  "#{cmd} #{params}"
end
