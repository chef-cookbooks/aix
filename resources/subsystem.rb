#
# Copyright:: 2008-2016, Chef Software, Inc.
# Copyright:: 2015-2016, Bloomberg Finance L.P.
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

property :subsystem_name, String, name_property: true
property :subsystem_synonym, String
property :arguments, String
property :program, String, required: true
property :user, String, default: 'root'
property :standard_output, String
property :standard_input, String
property :standard_error, String
property :auto_restart, [true, false], default: false
property :multiple_instances, [true, false], default: false
property :use_signals, [true, false], default: true
property :use_sockets, [true, false], default: false
property :use_message_queues, [true, false], default: false
property :message_queue_key, String
property :message_type, String
property :priority, Integer
# default normal_stop_signal is SIGTERM
property :normal_stop_signal, Integer, default: 15, equal_to: (1..34).to_a
# default force_stop_signal is SIGKILL
property :force_stop_signal, Integer, default: 9, equal_to: (1..34).to_a
property :show_inactive, [true, false], default: true
property :wait_time, Integer
property :subsystem_group, String

attr_accessor :exists

load_current_value do |desired|
  so = shell_out("lssrc -S -s #{subsystem_name}")
  current_value_does_not_exist! if so.stdout.lines.empty?
  fields = so.stdout.lines.last.chomp.split(':')
  # Documentation of fields from https://www-01.ibm.com/support/knowledgecenter/ssw_aix_71/com.ibm.aix.files/srcobj.h.htm
  # Format is below
  # subsysname:synonym:cmdargs:path:uid:auditid:standin:standout:standerr:action:multi:contact:svrkey:svrmtype:priority:signorm:sigforce:display:waittime:grpname:
  desired.subsystem_name(fields[0])
  desired.subsystem_synonym(fields[1])
  desired.arguments(fields[2])
  desired.program(fields[3])
  desired.user(Etc.getpwuid(fields[4].to_i).name)
  # ignore auditid
  desired.standard_input(fields[6])
  desired.standard_output(fields[7])
  desired.standard_error(fields[8])
  desired.auto_restart(fields[9] == '-R')
  desired.multiple_instances(fields[10] == '-Q')
  case fields[11]
  when '-S'
    desired.use_signals(true)
  when '-K'
    desired.use_sockets(true)
  when '-I'
    desired.use_message_queues(true)
  end
  desired.message_queue_key(fields[12])
  desired.message_type(fields[13])
  desired.priority(fields[14].to_i)
  desired.normal_stop_signal(fields[15].to_i)
  desired.force_stop_signal(fields[16].to_i)
  desired.show_inactive(fields[17] == '-d')
  desired.wait_time(fields[18].to_i)
  desired.subsystem_group(fields[19])
end

action_class do
  # Returns true if current_resource is not equal to new_resource
  def resource_changed?
    (new_resource.subsystem_synonym && current_resource.subsystem_synonym != new_resource.subsystem_synonym) ||
      (new_resource.arguments && current_resource.arguments != new_resource.arguments) ||
      (new_resource.program && current_resource.program != new_resource.program) ||
      (new_resource.user && current_resource.user != new_resource.user) ||
      (new_resource.standard_input && current_resource.standard_input != new_resource.standard_input) ||
      (new_resource.standard_output && current_resource.standard_output != new_resource.standard_output) ||
      (new_resource.standard_error && current_resource.standard_error != new_resource.standard_error) ||
      (new_resource.auto_restart && current_resource.auto_restart != new_resource.auto_restart) ||
      (new_resource.multiple_instances && current_resource.multiple_instances != new_resource.multiple_instances) ||
      (new_resource.use_signals && current_resource.use_signals != new_resource.use_signals) ||
      (new_resource.use_sockets && current_resource.use_sockets != new_resource.use_sockets) ||
      (new_resource.message_queue_key && current_resource.message_queue_key != new_resource.message_queue_key) ||
      (new_resource.message_type && current_resource.message_type != new_resource.message_type) ||
      (new_resource.priority && current_resource.priority != new_resource.priority) ||
      (new_resource.normal_stop_signal && current_resource.normal_stop_signal != new_resource.normal_stop_signal) ||
      (new_resource.force_stop_signal && current_resource.force_stop_signal != new_resource.force_stop_signal) ||
      (new_resource.show_inactive && current_resource.show_inactive != new_resource.show_inactive) ||
      (new_resource.wait_time && current_resource.wait_time != new_resource.wait_time) ||
      (new_resource.subsystem_group && current_resource.subsystem_group != new_resource.subsystem_group)
  end
end

action :create do
  cmd = []
  cmd << ['-t', new_resource.subsystem_synonym] unless new_resource.subsystem_synonym.empty?
  cmd << ['-a', "\"#{new_resource.arguments}\""] if new_resource.arguments
  cmd << ['-p', new_resource.program]
  cmd << ['-u', new_resource.user]
  cmd << ['-i', new_resource.standard_input] if new_resource.standard_input
  cmd << ['-o', new_resource.standard_output] if new_resource.standard_output
  cmd << ['-e', new_resource.standard_error] if new_resource.standard_error
  cmd << ['-q'] if new_resource.multiple_instances
  cmd << ['-R'] if new_resource.auto_restart
  cmd << ['-S'] if new_resource.use_signals
  cmd << ['-K'] if new_resource.use_sockets
  cmd << ['-I', new_resource.message_queue_key] if new_resource.use_message_queues && new_resource.message_queue_key
  cmd << ['-m', new_resource.message_type] if new_resource.use_message_queues && new_resource.message_type
  cmd << ['-E', new_resource.priority] if new_resource.priority
  cmd << ['-n', new_resource.normal_stop_signal] if new_resource.use_signals && new_resource.normal_stop_signal
  cmd << ['-f', new_resource.force_stop_signal] if new_resource.use_signals && new_resource.force_stop_signal
  cmd << ['-D'] unless new_resource.show_inactive
  cmd << ['-w', new_resource.wait_time] if new_resource.wait_time
  cmd << ['-G', new_resource.subsystem_group] if new_resource.subsystem_group

  if current_resource.nil?
    converge_by('create subsystem entry') do
      shell_out!(["mkssys -s #{new_resource.subsystem_name}"].concat(cmd).flatten.join(' '))
    end
  else
    unless current_resource.subsystem_name == new_resource.subsystem_name
      cmd << ['-s', new_resource.subsystem_name]
    end
    if resource_changed?
      converge_by('change subsystem entry') do
        shell_out!(["chssys -s #{current_resource.subsystem_name}"].concat(cmd).flatten.join(' '))
      end
    end
  end
end

action :delete do
  if current_resource.exists
    converge_by('remove subsystem entry') do
      shell_out!("rmssys -s #{current_resource.subsystem_name}")
    end
  end
end
