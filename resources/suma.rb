#
# Copyright 2016, International Business Machines Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include AIX::PatchMgmt

##############################
# PROPERTIES
##############################
property :desc, String, name_property: true
property :oslevel, String
property :location, String
property :targets, String
property :save_it, [true, false], default: false
property :sched_time, String
property :task_id, Integer
property :preview_only, [true, false], default: false

default_action :download

##############################
# load_current_value
##############################
load_current_value do
=begin
  task_id = -1
  hash = {}
  hash_info = {}
  so = shell_out!('/usr/sbin/suma -l')
  so.stdout.each_line do |line|
    line.chomp!
    if line =~ /^([0-9]+):$/
      task_id = Regexp.last_match(1)
    elsif line =~ /^\s+(.*?)=(.*?)$/
      hash_info[Regexp.last_match(1)] = Regexp.last_match(2)
    elsif line.empty?
      hash[task_id] = Hash[hash_info]
      hash_info.clear
    end
  end
  # puts hash
=end
end

##############################
# ACTION: download
##############################
action :download do
  # check ohai nim info
  check_nim_info(node)

  # obtain suma parameters
  params = suma_params(node, desc, oslevel, location, targets)
  return if params.nil?

  # suma preview
  suma = Suma.new(params)
  suma.preview
  return if preview_only == true
  return unless suma.downloaded?

  # suma download
  converge_by("download #{suma.downloaded} fixes to '#{params['DLTarget']}'") do
    suma.download
  end
  return if suma.failed? || LppSource.exist?(params['LppSource'], node)

  # create nim lpp source
  nim = Nim.new
  converge_by("define nim lpp source \'#{params['LppSource']}\'") do
    nim.define_lpp_source(params['LppSource'], params['DLTarget'])
  end
end

##############################
# ACTION: list
##############################
action :list do
  so = shell_out!('/usr/sbin/suma -l ' + task_id.to_s)
  converge_by("Suma tasks:\n#{so.stdout}") do
  end
end

##############################
# ACTION: edit
##############################
action :edit do
  suma_s = '/usr/sbin/suma'

  # TODO: treat fields

  if property_is_set?(:sched_time)
    if sched_time.empty?
      # unschedule
      suma_s << ' -u'
    else
      # schedule
      minute, hour, day, month, weekday = sched_time.split(' ')
      raise SumaError unless minute.eql?('*') || (0 <= minute.to_i && minute.to_i <= 59)
      raise SumaError unless hour.eql?('*') || (0 <= hour.to_i && hour.to_i <= 23)
      raise SumaError unless day.eql?('*') || (1 <= day.to_i && day.to_i <= 31)
      raise SumaError unless month.eql?('*') || (1 <= month.to_i && month.to_i <= 12)
      raise SumaError unless weekday.eql?('*') || (0 <= weekday.to_i && weekday.to_i <= 6)
      Chef::Log.debug("minute=#{minute}, hour=#{hour}, day=#{day}, month=#{month}, weekday=#{weekday}")
      suma_s << ' -s "' << sched_time << '"'
    end
  else
    # save
    suma_s << ' -w'
  end

  raise MissingTaskIdProperty, 'Please provide a task_id property to edit !' unless property_is_set?(:task_id)
  suma_s << ' ' << task_id.to_s

  Chef::Log.warn(suma_s)
  converge_by("Edit suma task #{task_id}") do
    shell_out!(suma_s)
  end
end

##############################
# ACTION: unschedule
##############################
action :unschedule do
  raise MissingTaskIdProperty, 'Please provide a task_id property to unschedule !' unless property_is_set?(:task_id)
  converge_by("Unschedule suma task #{task_id}") do
    shell_out!('/usr/sbin/suma -u ' + task_id.to_s)
  end
end

##############################
# ACTION: delete
##############################
action :delete do
  raise MissingTaskIdProperty, 'Please provide a task_id property to delete !' unless property_is_set?(:task_id)
  converge_by("Delete suma task #{task_id}") do
    shell_out!('/usr/sbin/suma -d ' + task_id.to_s)
  end
end

##############################
# ACTION: config
##############################
action :config do
  so = shell_out!('/usr/sbin/suma -c')
  converge_by("Suma global configuration settings:\n#{so.stdout}") do
  end
end

##############################
# ACTION: default
##############################
action :default do
  so = shell_out!('/usr/sbin/suma -D')
  converge_by("Suma default task:\n#{so.stdout}") do
  end
end
