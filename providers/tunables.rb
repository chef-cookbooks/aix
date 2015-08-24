#
# Author:: Alain Dejoux (<adejoux@djouxtech.net>)
# Cookbook Name:: aix
# Provider:: tunables
#
# Copyright:: 2015, Alain Dejoux
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

# get command name
def cmd
  @new_resource.mode.to_s
end

# generate command line
def gen_shell_out(params: nil, tunable: nil)
  params = " -p #{params}" if @new_resource.permanent
  if tunable and [ "R", "B", "I"].include? @current_resource.tunables[tunable][:type]
    params.sub! "-p", "-r"
  end
  "#{cmd} #{params}"
end

# loading current resource
def load_current_resource
  @current_resource = Chef::Resource::AixTunables.new(@new_resource.name)

  so = shell_out("#{cmd} -x")
  if so.exitstatus != 0
    raise("#{cmd}: error running #{cmd} -x")
  end

  # initializing tunables attribute
  all_tunables = Hash.new
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
    current_tunable = line.split(",")
    all_tunables[current_tunable[0].to_sym] = {
      :current => current_tunable[1],
      :default => current_tunable[2],
      :reboot => current_tunable[3],
      :min => current_tunable[4],
      :max => current_tunable[5],
      :unit => current_tunable[6],
      :type => current_tunable[7],
      :dtunable => current_tunable[8] || "none"
    }
  end
  @current_resource.tunables(all_tunables)
  Chef::Log.debug(@current_resource.tunables)
end

# update action
action :update do
  # for each tunables ...
  Chef::Log.debug(@new_resource.tunables)
  @new_resource.tunables.each do |tunable,value|
    # raise error if tunable doesn't exist
    unless @current_resource.tunables.has_key?(tunable.intern)
      raise "#{cmd}: #{tunable} does not exist"
    end

    Chef::Log.debug("#{cmd}: setting tunable #{tunable} with value #{value}")
    # next if value already set
    if @current_resource.tunables[tunable.intern][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to value #{value}")
    else
      Chef::Log.debug("#{cmd}: #{tunable} will be set to value #{value}")
      converge_by("#{cmd}: setting tunable #{tunable}=#{value}") do
        string_shell_out = gen_shell_out params: "-o #{tunable}=#{value} ", tunable: tunable.intern
        Chef::Log.debug("command: #{string_shell_out}")
        so = shell_out(string_shell_out)
        # if the command fails raise and exception
        if so.exitstatus != 0
          raise "no: #{string_shell_out} failed"
        end
      end
    end
  end
end

# reset action
action :reset do
  # for each tunables ...
  Chef::Log.debug(@new_resource.tunables)
  @new_resource.tunables.each do |tunable,value|
    # raise error if tunable doesn't exist
    unless @current_resource.tunables.has_key?(tunable.intern)
      raise "#{cmd}: #{tunable} does not exist"
    end

    if @current_resource.tunables[tunable.intern][:current] == value.to_s
      Chef::Log.info("#{cmd}: tunable #{tunable} is already set to default value #{value}")
    else
      Chef::Log.debug("#{cmd}: reseting tunable #{tunable}")
      converge_by("#{cmd}: reseting tunable #{tunable}") do
        string_shell_out = gen_shell_out params: " -d #{tunable}", tunable: tunable.intern
        Chef::Log.debug("command: #{string_shell_out}")
        so = shell_out(string_shell_out)
        # if the command fails raise and exception
        if so.exitstatus != 0
          raise "#{cmd}: #{string_shell_out} failed"
        end
      end
    end
  end
end

action :reset_all do
  converge_by("#{cmd} : resetting all") do
    string_shell_out = "#{cmd} -D"
    if @new_resource.nextboot
      string_shell_out = "yes | #{cmd} -r -D"
    end
    so = shell_out(string_shell_out)
  end
end

private :cmd, :gen_shell_out
