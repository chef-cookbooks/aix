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
property :task_id, Fixnum
property :preview_only, [true, false], default: false

default_action :download

##############################
# load_current_value
##############################
load_current_value do
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
end

##############################
# DEFINITIONS
##############################
class InvalidOsLevelProperty < StandardError
end

class InvalidLocationProperty < StandardError
end

def compute_rq_type
  if property_is_set?(:oslevel)
    if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
      rq_type = 'TL'
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      rq_type = 'SP'
    elsif oslevel.empty? || oslevel.casecmp('latest') == 0
      rq_type = 'Latest'
    else
      raise InvalidOsLevelProperty, 'Error: oslevel is not recognized'
    end
  else # default
    rq_type = 'Latest'
  end
  rq_type
end

def compute_filter_ml(targets, oslevel)
  # build machine-oslevel hash
  hash = Hash.new { |h, k| h[k] = (k == 'master') ? node['nim']['master'].fetch('oslevel', nil) : node['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
  targets.each { |k| hash[k] }
  hash.delete_if { |_k, v| v.nil? || v.empty? || v.to_i != oslevel.to_i }
  Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")

  unless hash.empty?
    # discover FilterML level
    ary = hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
    # find lowest ML
    filter_ml = ary.min
  end

  if filter_ml.nil?
    raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets'
  else
    filter_ml.insert(4, '-')
  end
  filter_ml
end

def compute_rq_name(rq_type, targets)
  case rq_type
  when 'Latest'
    # build machine-oslevel hash
    hash = Hash.new { |h, k| h[k] = (k == 'master') ? node['nim']['master'].fetch('oslevel', nil) : node['nim']['clients'].fetch(k, {}).fetch('oslevel', nil) }
    targets.each { |k| hash[k] }
    hash.delete_if { |_k, v| v.nil? || v.empty? }
    Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")
    unless hash.empty?
      # discover FilterML level
      ary = hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
      # find highest ML
      metadata_filter_ml = ary.max
      # check ml level of machines
      if ary.min[0..3].to_i < ary.max[0..3].to_i
        Chef::Log.warn("Release level mismatch, only AIX #{ary.max[0]}.#{ary.max[1]} SP/TL will be downloaded")
      end
    end
    if metadata_filter_ml.nil?
      raise InvalidTargetsProperty, 'Error: cannot discover filter ml based on the list of targets'
    else
      metadata_filter_ml.insert(4, '-')
    end
    Chef::Log.info("Found highest ML #{metadata_filter_ml} from client list")

    # suma metadata
    tmp_dir = "#{Chef::Config[:file_cache_path]}/metadata"
    suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
    suma.metadata

    # find latest SP for highest TL
    sps = shell_out("ls #{tmp_dir}/installp/ppc/*.install.tips.html").stdout.split
    sps.collect! do |file|
      file.gsub!('install.tips.html', 'xml')
      text = ::File.open(file).read
      text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1].delete('-')
    end
    rq_name = sps.max
    unless rq_name.nil?
      rq_name.insert(4, '-')
      rq_name.insert(7, '-')
      rq_name.insert(10, '-')
    end
    ::File.delete(tmp_dir)
    Chef::Log.info("Discover RqName #{rq_name} with metadata suma command")

  when 'TL'
    # pad with 0
    rq_name = "#{oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1]}-00-0000"

  when 'SP'
    if oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4}$/
      rq_name = oslevel
    elsif oslevel =~ /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/
      # suma metadata
      metadata_filter_ml = oslevel.match(/^([0-9]{4}-[0-9]{2})-[0-9]{2}$/)[1]
      tmp_dir = "#{Chef::Config[:file_cache_path]}/metadata"
      suma = Suma.new(desc, 'Latest', nil, metadata_filter_ml, tmp_dir)
      suma.metadata

      # find SP build number
      text = ::File.open("#{tmp_dir}/installp/ppc/#{oslevel}.xml").read
      rq_name = text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
	  ::File.delete(tmp_dir)
      Chef::Log.info("Discover RqName #{rq_name} with metadata suma command")
    end
  end
  rq_name
end

def compute_lpp_source_name(rq_name)
  if property_is_set?(:location)
    location.chomp!('\/')
    lpp_source = (location.start_with?('/') || location.empty?) ? "#{rq_name}-lpp_source" : location
  else # default
    lpp_source = "#{rq_name}-lpp_source"
  end
  lpp_source
end

def compute_dl_target(lpp_source)
  if property_is_set?(:location)
    location.chomp!('\/')
    if location.start_with?('/')
      dl_target = "#{location}/#{lpp_source}"
      unless node['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil).nil?
        Chef::Log.debug("Found lpp source '#{lpp_source}' location")
        unless node['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
          raise InvalidLocationProperty, 'Error: lpp source location mismatch'
        end
      end
    elsif location.empty? # empty
      dl_target = "/usr/sys/inst.images/#{lpp_source}"
    else # directory
      begin
        dl_target = node['nim']['lpp_sources'].fetch(location).fetch('location')
        Chef::Log.debug("Discover '#{location}' lpp source's location: '#{dl_target}'")
      rescue KeyError
        raise InvalidLocationProperty, "Error: cannot find lpp_source '#{location}' from Ohai output"
      end
    end
  else # default
    dl_target = "/usr/sys/inst.images/#{lpp_source}"
  end
  dl_target
end

def suma_params
  params = {}

  # build list of targets
  target_list = expand_targets(node['nim']['clients'].keys)
  Chef::Log.debug("target_list=#{target_list}")

  # compute suma request type based on oslevel property
  rq_type = compute_rq_type
  Chef::Log.debug("rq_type=#{rq_type}")
  params['rq_type'] = rq_type

  # compute suma filter ml based on targets property
  filter_ml = compute_filter_ml(target_list, oslevel)
  Chef::Log.debug("filter_ml=#{filter_ml}")
  params['filter_ml'] = filter_ml

  # check ml level of machines against expected oslevel
  # case rq_type
  # when 'SP', 'TL'
  #   if filter_ml[0..3].to_i < oslevel.match(/^([0-9]{4})-[0-9]{2}(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].to_i
  #     raise InvalidOsLevelProperty, 'Error: cannot upgrade machines to a new release using suma'
  #   end
  # end

  # compute suma request name based on metadata info
  rq_name = compute_rq_name(rq_type, target_list)
  Chef::Log.debug("rq_name=#{rq_name}")
  params['rq_name'] = rq_name

  # metadata does not match any fixes
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

##############################
# ACTION: download
##############################
action :download do
  # check ohai nim info
  check_ohai

  # obtain suma parameters
  params = suma_params
  return if params.nil?

  # suma preview
  suma = Suma.new(desc, params['rq_type'], params['rq_name'], params['filter_ml'], params['dl_target'])
  suma.preview
  return if preview_only == true

  if suma.dl.to_f > 0
    # suma download
    converge_by("download #{suma.downloaded} fixes to '#{params['dl_target']}'") do
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

##############################
# ACTION: unschedule
##############################
action :unschedule do
  if property_is_set?(:task_id)
    converge_by("Unschedule suma task #{task_id}") do
      shell_out!('/usr/sbin/suma -u ' + task_id.to_s)
    end
  else
    raise MissingTaskIdProperty, 'Please provide a task_id property to unschedule !'
  end
end

##############################
# ACTION: delete
##############################
action :delete do
  if property_is_set?(:task_id)
    converge_by("Delete suma task #{task_id}") do
      shell_out!('/usr/sbin/suma -d ' + task_id.to_s)
    end
  else
    raise MissingTaskIdProperty, 'Please provide a task_id property to delete !'
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
