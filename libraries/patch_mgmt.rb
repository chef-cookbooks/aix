# Author:: IBM Corporation
# Cookbook Name:: aix
# Provider:: nim
#
# Copyright:: 2016, Atos
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


class OhaiNimPluginNotFound < StandardError
end

class InvalidOsLevelProperty < StandardError
end

class InvalidLocationProperty < StandardError
end

class InvalidLppSourceProperty < StandardError
end

class InvalidTargetsProperty < StandardError
end

class SumaError < StandardError
end

class SumaPreviewError < SumaError
end

class SumaDownloadError < SumaError
end

class SumaMetadataError < SumaError
end

class NimError < StandardError
end

class NimCustError < NimError
end

class NimDefineError < NimError
end

class OsLevel
  include Comparable
  attr :str
  def <=>(oslevel)
    if str.delete('-').to_i < oslevel.str.delete('-').to_i
      -1
    elsif str.delete('-').to_i > oslevel.str.delete('-').to_i
      1
    else
      0
    end
  end
  def initialize(str)
    @str = str
  end
end

=begin
class Numeric
  def duration
    secs  = self.to_int
    mins  = secs / 60
    hours = mins / 60
    days  = hours / 24

    if days > 0
      "#{days} days and #{hours % 24} hours"
    elsif hours > 0
      "#{hours} hours and #{mins % 60} mins"
    elsif mins > 0
      "#{mins} mins #{secs % 60} secs"
    elsif secs >= 0
      "#{secs} secs"
    end
  end
end
=end

def print_hash_by_columns (data)
  widths={}
  data.keys.each do |key|
    widths[key] = 5   # minimum column width
    # longest string len of values
    val_len = data[key].max_by{ |v| v.to_s.length }.to_s.length
    widths[key] = (val_len > widths[key]) ? val_len : widths[key]
    # length of key
    widths[key] = (key.to_s.length > widths[key]) ? key.to_s.length : widths[key]
  end

  result = "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  result += "|"
  data.keys.each {|key| result += key.to_s.center(widths[key]+2) + "|" }
  result += "\n"
  result += "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  length=data.values.max_by{ |v| v.length }.length
  for i in 0.upto(length-1)
    result += "|"
    data.keys.each { |key| result += data[key][i].to_s.center(widths[key]+2) + "|" }
    result += "\n"
  end
  result += "+"
  data.keys.each {|key| result += "".center(widths[key]+2, '-') + "+" }
  result += "\n"
  result
end

def check_ohai
  # get list of all NIM machines from Ohai
  begin
    all_machines=node.fetch('nim', {}).fetch('clients').keys
    Chef::Log.debug("Ohai client machine's list is #{all_machines}")
  rescue Exception => e
    raise OhaiNimPluginNotFound, "Error: cannot find nim info from Ohai output"
  end
end

def expand_targets
  selected_machines=Array.new
  # compute list of machines based on targets property
  if property_is_set?(:targets)
    if !targets.empty?
      targets.split(/[,\s]/).each do |machine|
        #if machine =~ /$\/.*?\/^/
          # machine is a regexp
		  #node['nim']['clients'].keys.each do |m|
            #if m =~ machine
              #selected_machines.concat(m.split)
            #end
          #end
		#else
          # expand wildcard
          machine.gsub!(/\*/,'.*?')
          node['nim']['clients'].keys.each do |m|
            if m =~ /^#{machine}$/
              selected_machines.concat(m.split)
            end
          end
        #end
      end
      selected_machines=selected_machines.sort.uniq
    else # empty
      selected_machines=node['nim']['clients'].keys.sort
      Chef::Log.warn("No targets specified, consider all nim standalone machines as targets")
    end
  else # default
    selected_machines=node['nim']['clients'].keys.sort
    Chef::Log.warn("No targets specified, consider all nim standalone machines as targets!")
  end
  Chef::Log.debug("List of targets expanded to #{selected_machines}")

  if selected_machines.empty?
    raise InvalidTargetsProperty, "Error: cannot contact any machines"
  end
  selected_machines
end

def check_lpp_source_name (lpp_source)
  begin
    if node['nim']['lpp_sources'].fetch(lpp_source)
      Chef::Log.debug("Found lpp source #{lpp_source}")
      oslevel=lpp_source.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})-lpp_source$/)[1]
    end
  rescue Exception => e
    raise InvalidLppSourceProperty, "Error: cannot find lpp_source \'#{lpp_source}\' from Ohai output"
  end
  oslevel
end

def compute_rq_type
  if property_is_set?(:oslevel)
    if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
      rq_type="TL"
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      rq_type="SP"
    elsif oslevel.empty? or oslevel.downcase.eql?("latest")
      rq_type="Latest"
    else
      raise InvalidOsLevelProperty, "Error: oslevel is not recognized"
    end
  else # default
    rq_type="Latest"
  end
  rq_type
end

def compute_filter_ml (targets)

  # build machine-oslevel hash
  hash=Hash.new{ |h,k| h[k] = node['nim']['clients'].fetch(k,{}).fetch('oslevel',nil) }
  targets.each { |k| hash[k] }
  hash.delete_if { |k,v| v.nil? }
  Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")

  # discover FilterML level
  ary=hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }

  # find lowest ML
  filter_ml=ary.min

  if filter_ml.nil?
    raise InvalidTargetsProperty, "Error: cannot discover filter ml based on the list of targets"
  else
    filter_ml.insert(4, '-')
  end
  filter_ml
end

def compute_rq_name (rq_type, targets)
  if property_is_set?(:tmp_dir)
    if tmp_dir.empty?
      tmp_dir="/usr/sys/inst.images"
    end
  else # default
    tmp_dir="/usr/sys/inst.images"
  end
  if ::File.directory?("#{tmp_dir}")
    shell_out!("rm -rf #{tmp_dir}/*")
  else
    shell_out!("mkdir -p #{tmp_dir}")
  end

  case rq_type
  when 'Latest'
    # build machine-oslevel hash
    hash=Hash.new{ |h,k| h[k] = node['nim']['clients'].fetch(k,{}).fetch('oslevel',nil) }
    targets.each { |key| hash[key] }
    hash.delete_if { |k,v| v.nil? }
    Chef::Log.debug("Hash table (machine/oslevel) built #{hash}")
    # discover FilterML level
    ary=hash.values.collect { |v| v.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].delete('-') }
    # check ml level of machines
    if ary.min[0..3].to_i < ary.max[0..3].to_i
      Chef::Log.warn("Release level mismatch")
    end
	# find highest ML
    metadata_filter_ml=ary.max
    if metadata_filter_ml.nil?
      raise InvalidTargetsProperty, "Error: cannot discover filter ml based on the list of targets"
    else
      metadata_filter_ml.insert(4, '-')
    end

    # find latest SP for highest TL
    suma_metadata_s="/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a Action=Metadata -a RqType=#{rq_type} -a DLTarget=#{tmp_dir} -a FilterML=#{metadata_filter_ml}"
    so=shell_out(suma_metadata_s)
    if so.error?
      raise SumaMetadataError, "Error: \"#{suma_metadata_s}\" returns \'#{so.stderr.chomp!}\'!\n#{so.stdout}"
    else
      Chef::Log.warn("Done suma metadata operation \"#{suma_metadata_s}\"")
      sps=shell_out("ls #{tmp_dir}/installp/ppc/*.install.tips.html").stdout.split
      Chef::Log.debug("sps=#{sps}")
      sps.collect! do |file|
        file.gsub!("install.tips.html","xml")
        text=::File.open(file).read
        text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1].delete('-')
      end
      rq_name=sps.max
	  unless rq_name.nil?
        rq_name.insert(4, '-')
        rq_name.insert(7, '-')
        rq_name.insert(10, '-')
      end
    end

  when 'TL'
    # pad with 0
    rq_name="#{oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1]}-00-0000"

  when 'SP'
    if oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})$/
      rq_name=$1
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2})-[0-9]{2}$/
      # find SP build number
      suma_metadata_s="/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a Action=Metadata -a RqType=Latest -a DLTarget=#{tmp_dir} -a FilterML=#{$1}"
      so=shell_out(suma_metadata_s)
      if so.error?
        raise SumaMetadataError, "Error: \"#{suma_metadata_s}\" returns \'#{so.stderr.chomp!}\'\n#{so.stdout}"
      else
        Chef::Log.warn("Done suma metadata operation \"#{suma_metadata_s}\"")
        text=::File.open("#{tmp_dir}/installp/ppc/#{oslevel}.xml").read
        rq_name=text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
      end
    end
  end
  rq_name
end

def compute_lpp_source_name (rq_name)
  if property_is_set?(:location)
    location.chomp!('\/')
    if location.start_with?("/") or location.empty?
      # location is a directory
	  lpp_source="#{rq_name}-lpp_source"
    else
      # location is a lpp source
      lpp_source=location
    end
  else # default
    lpp_source="#{rq_name}-lpp_source"
  end
  lpp_source
end

def compute_dl_target (lpp_source)
  if property_is_set?(:location)
    location.chomp!('\/')
    if location.start_with?("/")
      dl_target="#{location}/#{lpp_source}"
      unless node['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil) == nil
        Chef::Log.debug("Found lpp source \'#{lpp_source}\' location")
        unless node['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
          raise InvalidLocationProperty, "Error: lpp source location mismatch"
        end
      end
    elsif location.empty? # empty
      dl_target="/usr/sys/inst.images/#{lpp_source}"
    else # directory
      begin
        dl_target=node['nim']['lpp_sources'].fetch(location).fetch('location')
        Chef::Log.debug("Discover \'#{location}\' lpp source's location: \'#{dl_target}\'")
      rescue Exception => e
        raise InvalidLocationProperty, "Error: cannot find lpp_source \'#{location}\' from Ohai output"
      end
    end
  else # default
    dl_target="/usr/sys/inst.images/#{lpp_source}"
  end
  dl_target
end
