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

property :desc, String, name_property: true
property :oslevel, String
property :location, String
property :targets, String
property :tmp_dir, String
property :save_it, [true, false], default: false
property :sched_time, String
property :task_id, Fixnum

default_action :download

load_current_value do
end

def suma_params
  params = {}

  # build list of targets
  target_list = expand_targets
  Chef::Log.debug("target_list=#{target_list}")

  # compute suma request type based on oslevel property
  rq_type = compute_rq_type
  Chef::Log.debug("rq_type=#{rq_type}")
  params['rq_type'] = rq_type

  # compute suma filter ml based on targets property
  filter_ml = compute_filter_ml(target_list)
  Chef::Log.debug("filter_ml=#{filter_ml}")
  params['filter_ml'] = filter_ml

  # check ml level of machines against expected oslevel
  case rq_type
  when 'SP', 'TL'
    if filter_ml[0..3].to_i < oslevel.match(/^([0-9]{4})-[0-9]{2}(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].to_i
      raise InvalidOsLevelProperty, 'Error: cannot upgrade machines to a new release using suma'
    end
  end

  # compute suma request name based on metadata info
  rq_name = compute_rq_name(rq_type, target_list)
  Chef::Log.debug("rq_name=#{rq_name}")
  params['rq_name'] = rq_name

  return nil if params['rq_name'].nil? || params['rq_name'].empty?

  # compute lpp source name based on request name
  lpp_source = compute_lpp_source_name(rq_name)
  Chef::Log.debug("lpp_source=#{lpp_source}")
  params['lpp_source'] = lpp_source

  # compute suma dl target based on lpp source name
  dl_target = compute_dl_target(lpp_source)
  Chef::Log.debug("dl_target=#{dl_target}")
  params['dl_target'] = dl_target

  params
end

action :preview do
  # inputs
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("oslevel=\"#{oslevel}\"")
  Chef::Log.debug("location=\"#{location}\"")
  Chef::Log.debug("targets=\"#{targets}\"")
  Chef::Log.debug("tmp_dir=\"#{tmp_dir}\"")
  Chef::Log.debug("save_it=\"#{save_it}\"")
  Chef::Log.debug("sched_time=\"#{sched_time}\"")

  # check ohai nim info
  check_ohai

  # obtain suma parameters
  params = suma_params
  return if params.nil?

  # create directory
  unless ::File.directory?(params['dl_target'])
    mkdir_s = "mkdir -p #{params['dl_target']}"
    converge_by("create directory \'#{params['dl_target']}\'") do
      shell_out!(mkdir_s)
    end
  end

  # suma preview
  suma = Suma.new(desc, params['rq_type'], params['rq_name'], params['filter_ml'], params['dl_target'])
  converge_by('preview download') do
    suma.preview(save_it)
  end
end

action :download do
  # inputs
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("oslevel=\"#{oslevel}\"")
  Chef::Log.debug("location=\"#{location}\"")
  Chef::Log.debug("targets=\"#{targets}\"")
  Chef::Log.debug("tmp_dir=\"#{tmp_dir}\"")
  Chef::Log.debug("save_it=\"#{save_it}\"")
  Chef::Log.debug("sched_time=\"#{sched_time}\"")

  # check ohai nim info
  check_ohai

  # obtain suma parameters
  params = suma_params
  return if params.nil?

  # create directory
  unless ::File.directory?(params['dl_target'])
    mkdir_s = "mkdir -p #{params['dl_target']}"
    converge_by("create directory \'#{params['dl_target']}\'") do
      shell_out!(mkdir_s)
    end
  end

  # suma preview
  suma = Suma.new(desc, params['rq_type'], params['rq_name'], params['filter_ml'], params['dl_target'])
  suma.preview

  if suma.dl.to_f > 0
    # suma download
    converge_by("download #{suma.downloaded} fixes") do
      suma.download(save_it)
    end

    # create nim lpp source
    if suma.failed.to_i == 0 && node['nim']['lpp_sources'].fetch(params['lpp_source'], nil).nil?
      nim = Nim.new
      converge_by("define nim lpp source \'#{params['lpp_source']}\'") do
        nim.define_lpp_source(params['lpp_source'], params['dl_target'])
      end
    end
  end
end

action :list do
  so = shell_out!('/usr/sbin/suma -l ' + task_id.to_s)
  converge_by("Suma tasks:\n#{so.stdout}") do
  end
end

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

  if property_is_set?(:task_id)
    suma_s << ' ' << task_id.to_s
  else
    raise MissingTaskIdProperty, 'Please provide a task_id property to edit !'
  end

  Chef::Log.warn(suma_s)
  converge_by("Edit suma task #{task_id}") do
    shell_out!(suma_s)
  end
end

action :unschedule do
  if property_is_set?(:task_id)
    converge_by("Unschedule suma task #{task_id}") do
      shell_out!('/usr/sbin/suma -u ' + task_id.to_s)
    end
  else
    raise MissingTaskIdProperty, 'Please provide a task_id property to delete !'
  end
end

action :delete do
  if property_is_set?(:task_id)
    converge_by("Delete suma task #{task_id}") do
      shell_out!('/usr/sbin/suma -d ' + task_id.to_s)
    end
  else
    raise MissingTaskIdProperty, 'Please provide a task_id property to delete !'
  end
end

action :config do
  so = shell_out!('/usr/sbin/suma -c')
  converge_by("Suma global configuration settings:\n#{so.stdout}") do
  end
end

action :default do
  so = shell_out!('/usr/sbin/suma -D')
  converge_by("Suma default task:\n#{so.stdout}") do
  end
end
