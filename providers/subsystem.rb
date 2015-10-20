#
# Cookbook: aix
# License: Apache 2.0
#
# Copyright 2008-2015, Chef Software, Inc.
# Copyright 2015, Bloomberg Finance L.P.
#

require 'chef/mixin/shell_out'
require 'etc'

include Chef::Mixin::ShellOut

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixSubsystem.new(@new_resource.name)
  @current_resource.exists = false
  so = shell_out("lssrc -S -s #{@new_resource.subsystem_name}")
  if !so.stdout.lines.empty?
    @current_resource.exists = true
    fields = so.stdout.lines.last.chomp.split(':')
    #Documentation of fields from https://www-01.ibm.com/support/knowledgecenter/ssw_aix_71/com.ibm.aix.files/srcobj.h.htm
    #Format is below
    #subsysname:synonym:cmdargs:path:uid:auditid:standin:standout:standerr:action:multi:contact:svrkey:svrmtype:priority:signorm:sigforce:display:waittime:grpname:
    @current_resource.subsystem_name(fields[0])
    @current_resource.subsystem_synonym(fields[1])
    @current_resource.arguments(fields[2])
    @current_resource.program(fields[3])
    @current_resource.user(Etc.getpwuid(fields[4].to_i).name)
    #ignore auditid
    @current_resource.standard_input(fields[6])
    @current_resource.standard_output(fields[7])
    @current_resource.standard_error(fields[8])
    @current_resource.auto_restart(fields[9] == '-R')
    @current_resource.multiple_instances(fields[10] == '-Q')
    case fields[11]
    when '-S'
      @current_resource.use_signals(true)
    when '-K'
      @current_resource.use_sockets(true)
    when '-I'
      @current_resource.use_message_queues(true)
    end
    @current_resource.message_queue_key(fields[12])
    @current_resource.message_type(fields[13])
    @current_resource.priority(fields[14].to_i)
    @current_resource.normal_stop_signal(fields[15].to_i)
    @current_resource.force_stop_signal(fields[16].to_i)
    @current_resource.show_inactive(fields[17] == '-d')
    @current_resource.wait_time(fields[18].to_i)
    @current_resource.subsystem_group(fields[19])
  end
end

# Returns true if current_resource is not equal to new_resource
def resource_changed?
  (@new_resource.subsystem_synonym && @current_resource.subsystem_synonym !=  @new_resource.subsystem_synonym) ||
  (@new_resource.arguments && @current_resource.arguments !=  @new_resource.arguments) ||
  (@new_resource.program && @current_resource.program !=  @new_resource.program) ||
  (@new_resource.user && @current_resource.user !=  @new_resource.user) ||
  (@new_resource.standard_input && @current_resource.standard_input !=  @new_resource.standard_input) ||
  (@new_resource.standard_output && @current_resource.standard_output !=  @new_resource.standard_output) ||
  (@new_resource.standard_error && @current_resource.standard_error !=  @new_resource.standard_error) ||
  (@new_resource.auto_restart && @current_resource.auto_restart !=  @new_resource.auto_restart) ||
  (@new_resource.multiple_instances && @current_resource.multiple_instances !=  @new_resource.multiple_instances) ||
  (@new_resource.use_signals && @current_resource.use_signals !=  @new_resource.use_signals) ||
  (@new_resource.use_sockets && @current_resource.use_sockets !=  @new_resource.use_sockets) ||
  (@new_resource.message_queue_key && @current_resource.message_queue_key !=  @new_resource.message_queue_key) ||
  (@new_resource.message_type && @current_resource.message_type !=  @new_resource.message_type) ||
  (@new_resource.priority && @current_resource.priority !=  @new_resource.priority) ||
  (@new_resource.normal_stop_signal && @current_resource.normal_stop_signal !=  @new_resource.normal_stop_signal) ||
  (@new_resource.force_stop_signal && @current_resource.force_stop_signal !=  @new_resource.force_stop_signal) ||
  (@new_resource.show_inactive && @current_resource.show_inactive !=  @new_resource.show_inactive) ||
  (@new_resource.wait_time && @current_resource.wait_time !=  @new_resource.wait_time) ||
  (@new_resource.subsystem_group && @current_resource.subsystem_group !=  @new_resource.subsystem_group)
end


action :create do
  command = []
  command << ['-t', new_resource.subsystem_synonym] if new_resource.subsystem_synonym
  command << ['-a', "\"#{new_resource.arguments}\""] if new_resource.arguments
  command << ['-p', new_resource.program]
  command << ['-u', new_resource.user]
  command << ['-i', new_resource.standard_input] if new_resource.standard_input
  command << ['-o', new_resource.standard_output] if new_resource.standard_output
  command << ['-e', new_resource.standard_error] if new_resource.standard_error
  command << ['-q'] if new_resource.multiple_instances
  command << ['-R'] if new_resource.auto_restart
  command << ['-S'] if new_resource.use_signals
  command << ['-K'] if new_resource.use_sockets
  command << ['-I', new_resource.message_queue_key] if new_resource.use_message_queues && new_resource.message_queue_key
  command << ['-m', new_resource.message_type] if new_resource.use_message_queues && new_resource.message_type
  command << ['-E', new_resource.priority] if new_resource.priority
  command << ['-n', new_resource.normal_stop_signal] if new_resource.use_signals && new_resource.normal_stop_signal
  command << ['-f', new_resource.force_stop_signal] if new_resource.use_signals && new_resource.force_stop_signal
  command << ['-D'] if !new_resource.show_inactive
  command << ['-w', new_resource.wait_time] if new_resource.wait_time
  command << ['-G', new_resource.subsystem_group] if new_resource.subsystem_group

  if @current_resource.exists
    unless @current_resource.subsystem_name == @new_resource.subsystem_name
      command << ['-s', @new_resource.subsystem_name]
    end
    if resource_changed?
      converge_by('change subsystem entry') do
        shell_out!(["chssys -s #{@current_resource.subsystem_name}"].concat(command).flatten.join(' '))
      end
    end
  else
    converge_by('create subsystem entry') do
      shell_out!(["mkssys -s #{@new_resource.subsystem_name}"].concat(command).flatten.join(' '))
    end
  end
end

action :delete do
  if @current_resource.exists
    converge_by('remove subsystem entry') do
      shell_out!("rmssys -s #{@current_resource.subsystem_name}")
    end
  end
end
