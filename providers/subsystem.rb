#
# Cookbook: aix
# License: Apache 2.0
#
# Copyright 2008-2015, Chef Software, Inc.
# Copyright 2015, Bloomberg Finance L.P.
#

require 'chef/mixin/shell_out'

include Chef::Mixin::ShellOut

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixSubsystem.new(@new_resource.name)
  @current_resource.exists = false
  so = shell_out("lssrc -S -s #{@new_resource.subsystem_name}")
  if so.exitstatus == 0
    @current_resource.exists = true
    fields = so.stdout.lines.last.chomp.split(':')
    #Documentation of fields from https://www-01.ibm.com/support/knowledgecenter/ssw_aix_71/com.ibm.aix.files/srcobj.h.htm
    #Format is below
    #subsysname:synonym:cmdargs:path:uid:auditid:standin:standout:standerr:action:multi:contact:svrkey:svrmtype:priority:signorm:sigforce:display:waittime:grpname:
    @current_resource.subsystem_name(fields[0])
    @current_resource.subsystem_synonym(fields[1])
    @current_resource.arguments(fields[2])
    @current_resource.program(fields[3])
    @current_resource.user(fields[4])
    #ignore auditid
    @current_resource.standard_input(fields[6])
    @current_resource.standard_output(fields[7])
    @current_resource.standard_error(fields[8])
    @current_resource.standard_error(fields[9])
    #ignore action
    @current_resource.multiple_instances(fields[11] == '-Q')
    case fields[12]
    when '-S'
      @current_resource.use_signals(true)
    when '-K'
      @current_resource.use_sockets(true)
    when '-I'
      @current_resource.use_message_queues(true)
    @current_resource.message_queue_key(fields[13])
    @current_resource.message_type(fields[14])
    @current_resource.priority(fields[15])
    @current_resource.normal_stop_signal(fields[16])
    @current_resource.force_stop_signal(fields[17])
    @current_resource.display(fields[18])
    @current_resource.wait_time(fields[19])
    @current_resource.group_name(fields[20])
  end
end

action :create do
  command = ['-p', new_resource.program]
  command << ['-u', new_resource.user]
  command << ['-a', "\"#{new_resource.arguments.join(' ')}\""] if new_resource.arguments
  command << ['-t', new_resource.subsystem_synonym] if new_resource.subsystem_synonym
  command << ['-G', new_resource.subsystem_group] if new_resource.subsystem_group
  command << ['-e', new_resource.standard_error] if new_resource.standard_error
  command << ['-i', new_resource.standard_input] if new_resource.standard_input
  command << ['-o', new_resource.standard_output] if new_resource.standard_output
  command << ['-q'] if new_resource.multiple_instances
  command << ['-S'] if new_resource.use_signals
  command << ['-f', new_resource.force_stop_signal] if new_resource.use_signals && new_resource.force_stop_signal
  command << ['-n', new_resource.normal_stop_signal] if new_resource.use_signals && new_resource.normal_stop_signal

  if @current_resource.exists
    unless @current_resource.subsystem_name == @new_resource.subsystem_name
      command << ['-s', @new_resource.subsystem_name]
    end
    converge_by('change subsystem entry') do
      shell_out!(["chssys -s #{@current_resource.subsystem_name}"].concat(command).flatten.join(' '))
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
      shell_out!("rmssys -s #{@current_resource.service_name}")
    end
  end
end
