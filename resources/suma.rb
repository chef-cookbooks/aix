# Author:: Jérôme Hurstel (<jerome.hurstel@atos.ne>) & Laurent Gay (<laurent.gay@atos.net>)
# Cookbook Name:: aix
# Provider:: suma
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

property :desc, String, name_property: true
property :oslevel, String
property :location, String
property :targets, String

class OhaiNimPluginNotFound < StandardError
end
class InvalidOsLevelProperty < StandardError
end
class InvalidLocationProperty < StandardError
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

load_current_value do
end

action :download do

  Chef::Log.info("desc=#{desc}")
  Chef::Log.info("oslevel=#{oslevel}")
  Chef::Log.info("location=#{location}")
  Chef::Log.info("targets=#{targets}")

  # compute suma request type based on oslevel property
  if property_is_set?(:oslevel)
    if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-[0-9]{4})$/
      rq_type="TL"
      rq_name=$1
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      rq_type="SP"
      rq_name=$1
    elsif oslevel.empty? or oslevel.downcase.eql?("latest")
      rq_type="Latest"
    else
      raise InvalidOsLevelProperty, "SUMA-SUMA-SUMA oslevel is not recognized!"
    end
  else
    rq_type="Latest"
  end
  Chef::Log.info("rq_type=#{rq_type}")
  Chef::Log.info("rq_name=#{rq_name}")

  # get list of all NIM machines from Ohai
  begin
    all_machines=node.fetch('nim', {}).fetch('clients').keys
    Chef::Log.info("Ohai client machine's list is #{all_machines}")
  rescue Exception => e
    raise OhaiNimPluginNotFound, "SUMA-SUMA-SUMA cannot find info from Ohai nim plugin!"
  end

  selected_machines=Array.new

  # compute list of machines based on targets property
  if property_is_set?(:targets)
    if !targets.empty?
      targets.split(',').each do |machine|
        if machine.match(/\*/)
          # expand wildcard
          machine.gsub!(/\*/,'.*?')
          all_machines.collect do |m|
            if m =~ /^#{machine}$/
              selected_machines.concat(m.split)
            end
          end
        else
          selected_machines.concat(machine.split)
        end
      end
      selected_machines=selected_machines.sort.uniq
    else
      selected_machines=all_machines.sort
      Chef::Log.warn("No targets specified, consider all nim clients as targets!")
    end
  else
    selected_machines=all_machines.sort
    Chef::Log.warn("No targets specified, consider all nim clients as targets!")
  end
  Chef::Log.info("List of targets expanded to #{selected_machines}")

  # build machine-oslevel hash
  hash=Hash[selected_machines.collect do |m|
    begin
      oslevel=node['nim']['clients'].fetch(m).fetch('oslevel')
      Chef::Log.info("Obtained OS level for machine \'#{m}\': #{oslevel}")
      oslevel=oslevel.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1]
      [ m, oslevel.delete('-') ]
    rescue Exception => e
      Chef::Log.warn("Cannot find OS level for machine \'#{m}\' into Ohai output")
      [ m, nil ]
    end
  end ]
  hash.delete_if { |key,value| value.nil? }

  # discover FilterML level
  filter_ml=nil
  if rq_type.eql?("Latest")
    # find highest
    filter_ml=hash.values.max
    unless filter_ml.nil?
      filter_ml.insert(4, '-')
      if filter_ml.to_i > hash.values.min.insert(4, '-').to_i
        Chef::Log.warn("Release level mismatch. Only targets at level \'#{filter_ml}\' will be updated !")
      end
  
      # find latest SP for highest TL
      tmp_dir="/suma_metadata"
      unless ::File.directory?("#{tmp_dir}")
        shell_out!("mkdir -p #{tmp_dir}")
      end
      suma_s="suma -x -a Action=Metadata -a RqType=#{rq_type} -a DLTarget=#{tmp_dir} -a FilterML=#{filter_ml}"
      Chef::Log.info("SUMA metadata operation: #{suma_s}")
      so=shell_out("#{suma_s}")
      if so.error?
        raise SumaMetadataError "SUMA-SUMA-SUMA suma metadata returns 1!"
      else
        Chef::Log.info("suma metadata returns 0")
        #shell_out!("rm -rf #{tmp_dir}")
        toto=shell_out("ls #{tmp_dir}/installp/ppc/*.html").stdout.split
        Chef::Log.info("toto=#{toto}")
        toto.collect { |tl| tl.match(/\/([0-9]{4}-[0-9]{2}-[0-9]{2}).install.tips.html$/)[1].delete('-') }
        rq_name=toto.max
        rq_name.insert(4, '-')
        rq_name.insert(7, '-')
        Chef::Log.info("rq_name=#{rq_name}")
      end
    end
  else
    # find lowest
    filter_ml=hash.values.min
    unless filter_ml.nil?
      filter_ml.insert(4, '-')
    end 
  end
  if filter_ml.nil?
    raise InvalidTargetsProperty, "SUMA-SUMA-SUMA cannot reach any clients!"
  end
  Chef::Log.info("Discover filter ML level \'#{filter_ml}\'")

  # create location if it does not exist
  if property_is_set?(:location)
    if location.start_with?("/")
      lpp_source="#{rq_name}-lpp_source"
      dl_target="#{location}/#{lpp_source}"
      unless node['nim']['lpp_sources'].fetch(lpp_source, {}).fetch('location', nil) == nil
        Chef::Log.info("Found lpp source \'#{lpp_source}\' location")
        unless node['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
          raise InvalidLocationProperty, "SUMA-SUMA-SUMA lpp source location mismatch"
        end
      end
    elsif location.empty?
      lpp_source="#{rq_name}-lpp_source"
      dl_target="/usr/sys/inst.images/#{lpp_source}"
    else
      begin
        lpp_source=location
        dl_target=node['nim']['lpp_sources'].fetch(location).fetch('location')
        Chef::Log.info("Discover \'#{location}\' lpp source's location: \'#{dl_target}\'")
      rescue Exception => e
        raise InvalidLocationProperty, "SUMA-SUMA-SUMA cannot find lpp_source \'#{location}\' into Ohai output"
      end
    end
  else
    lpp_source="#{rq_name}-lpp_source"
    dl_target="/usr/sys/inst.images/#{lpp_source}"
  end
  unless ::File.directory?("#{dl_target}")
    Chef::Log.info("Creating location \'#{dl_target}\'...")
    shell_out!("mkdir -p #{dl_target}")
    Chef::Log.warn("Directory \'#{dl_target}\' has been created.")
  end

  # suma preview
  suma_s="suma -x -a DisplayName=\"#{desc}\" -a RqType=#{rq_type} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  unless rq_type.eql?("Latest")
    suma_s << " -a RqName=#{rq_name}"
  end
  dl=0
  Chef::Log.info("SUMA preview operation: #{suma_s}")
  so=shell_out("LANG=C #{suma_s} -a Action=Preview")
  if so.error?
    if so.stderr =~ /0500-035 No fixes match your query./
      Chef::Log.info("SUMA-SUMA-SUMA error: #{so.stderr}")
    else
      raise SumaPreviewError, "SUMA-SUMA-SUMA error:\n#{so.stderr}"
    end
  else
    Chef::Log.info("#{so.stdout}")
    if so.stdout =~ /([0-9]+) downloaded/
      downloaded=$1
      dl=so.stdout.match(/Total bytes of updates downloaded: ([0-9]+)/)[1].to_f/1024/1024/1024
      timeout=600+dl.to_f*900  # 10 min + 15 min / GB
      if downloaded.to_i > 0
        Chef::Log.warn("#{downloaded} fixes (~ #{dl.to_f.round(2)} GB) will be downloaded to \'#{dl_target}\' directory. It may take up to #{Time.at(timeout).strftime("%Hh:%Mm:%Ss")}.")
      end
    end
    if so.stdout =~ /([0-9]+) failed/
      failed=$1
      Chef::Log.info("#{failed} failed fixes")
      if failed.to_i > 0
        Chef::Log.warn("Preview of #{failed} fixes has failed. Only download will be done, no lpp source created.")
      end
    end
  end

  unless dl.to_f == 0
    # suma download
    converge_by("suma download operation: \"#{suma_s}\"") do
      Chef::Log.info("Download fixes with #{timeout.to_i}s timeout...")
      so=shell_out!("#{suma_s} -a Action=Download", :timeout => timeout.to_i)
    end

    unless failed.to_i > 0 or node['nim']['lpp_sources'].fetch(lpp_source, nil) == nil
      # nim define
      nim_s="nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{lpp_source}"
      converge_by("nim define lpp_source: \"#{nim_s}\"") do
        Chef::Log.info("Define #{lpp_source} ...")
        so=shell_out!("#{nim_s}")
      end
    end

  end

end
