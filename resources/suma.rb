#
# Copyright:: 2016, Atos <jerome.hurstel@atos.net>
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

property :desc, String, name_property: true
property :oslevel, String
property :location, String
property :targets, String
property :tmp_dir, String

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

def compute_rq_type
  if property_is_set?(:oslevel)
    if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/
      rq_type = 'TL'
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/
      rq_type = 'SP'
    elsif oslevel.empty? || oslevel.casecmp('latest') == 0
      rq_type = 'Latest'
    else
      raise InvalidOsLevelProperty, 'SUMA-SUMA-SUMA oslevel is not recognized'
    end
  else
    rq_type = 'Latest'
  end
  rq_type
end

def compute_filter_ml(rq_type)
  # get list of all NIM machines from Ohai
  begin
    all_machines = node.fetch('nim', {}).fetch('clients').keys
    Chef::Log.info("Ohai client machine's list is #{all_machines}")
  rescue Exception => e
    raise OhaiNimPluginNotFound, 'SUMA-SUMA-SUMA cannot find nim info from Ohai output'
  end

  selected_machines = []

  # compute list of machines based on targets property
  if property_is_set?(:targets)
    if !targets.empty?
      targets.split(',').each do |machine|
        if machine =~ /\*/
          # expand wildcard
          machine.gsub!(/\*/, '.*?')
          all_machines.collect do |m|
            selected_machines.concat(m.split) if m =~ /^#{machine}$/
          end
        else
          selected_machines.concat(machine.split)
        end
      end
      selected_machines = selected_machines.sort.uniq
    else
      selected_machines = all_machines.sort
      Chef::Log.warn('No targets specified, consider all nim standalone machines as targets')
    end
  else
    selected_machines = all_machines.sort
    Chef::Log.warn('No targets specified, consider all nim standalone machines as targets')
  end
  Chef::Log.info("List of targets expanded to #{selected_machines}")

  # build machine-oslevel hash
  hash = Hash[selected_machines.collect do |m|
    begin
      client_oslevel = node['nim']['clients'].fetch(m).fetch('oslevel')
      Chef::Log.info("Obtained OS level for machine \'#{m}\': #{client_oslevel}")
      client_mllevel = client_oslevel.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1]
      [m, client_mllevel]
    rescue Exception => e
      Chef::Log.warn("Cannot find OS level for machine \'#{m}\' from Ohai output")
      [m, nil]
    end
  end]
  hash.delete_if { |_key, value| value.nil? }
  Chef::Log.info("Hash table (machine/mllevel) built #{hash}")

  # discover FilterML level
  ary = hash.values.collect { |ml| ml.delete('-') }
  case rq_type
  when 'Latest'
    # check ml level of machines
    if ary.min[0..3].to_i < ary.max[0..3].to_i
      Chef::Log.warn('Release level mismatch')
    end
    # find highest ML
    filter_ml = ary.max
  when 'SP', 'TL'
    # find lowest ML
    filter_ml = ary.min
  end
  if filter_ml.nil?
    raise InvalidTargetsProperty, 'SUMA-SUMA-SUMA cannot discover filter ml'
  else
    filter_ml.insert(4, '-')
  end
  filter_ml
end

def compute_rq_name(rq_type, filter_ml)
  if property_is_set?(:tmp_dir)
    tmp_dir = '/usr/sys/inst.images' if tmp_dir.empty?
  else
    tmp_dir = '/usr/sys/inst.images'
  end
  if ::File.directory?(tmp_dir.to_s)
    shell_out!("rm -rf #{tmp_dir}/*")
  else
    shell_out!("mkdir -p #{tmp_dir}")
  end

  case rq_type
  when 'Latest'
    # find latest SP for highest TL
    suma_metadata_s = "/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a Action=Metadata -a RqType=#{rq_type} -a DLTarget=#{tmp_dir} -a FilterML=#{filter_ml}"
    so = shell_out(suma_metadata_s)
    if so.error?
      raise SumaMetadataError, "SUMA-SUMA-SUMA \"#{suma_metadata_s}\" returns \'#{so.stderr.chomp!}\'!\n#{so.stdout}"
    else
      Chef::Log.warn("Done suma metadata operation \"#{suma_metadata_s}\"")
      sps = shell_out("ls #{tmp_dir}/installp/ppc/*.install.tips.html").stdout.split
      Chef::Log.info("sps=#{sps}")
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
    end

  when 'TL'
    # pad with 0
    rq_name = "#{oslevel.match(/^([0-9]{4}-[0-9]{2})(|-00|-00-0000)$/)[1]}-00-0000"

  when 'SP'
    if oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})$/
      rq_name = Regexp.last_match(1)
    elsif oslevel =~ /^([0-9]{4}-[0-9]{2})-[0-9]{2}$/
      # find SP build number
      suma_metadata_s = "/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a Action=Metadata -a RqType=Latest -a DLTarget=#{tmp_dir} -a FilterML=#{Regexp.last_match(1)}"
      so = shell_out(suma_metadata_s)
      if so.error?
        raise SumaMetadataError, "SUMA-SUMA-SUMA \"#{suma_metadata_s}\" returns \'#{so.stderr.chomp!}\'\n#{so.stdout}"
      else
        Chef::Log.warn("Done suma metadata operation \"#{suma_metadata_s}\"")
        text = ::File.open("#{tmp_dir}/installp/ppc/#{oslevel}.xml").read
        rq_name = text.match(/^<SP name="([0-9]{4}-[0-9]{2}-[0-9]{2}-[0-9]{4})">$/)[1]
      end
    end
  end
  rq_name
end

def compute_lpp_source_name(rq_name)
  if property_is_set?(:location)
    location.chomp!('\/')
    lpp_source = if location.start_with?('/') || location.empty?
                   # location is a directory
                   "#{rq_name}-lpp_source"
                 else
                   # location is a lpp source
                   location
                 end
  else
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
        Chef::Log.info("Found lpp source \'#{lpp_source}\' location")
        unless node['nim']['lpp_sources'][lpp_source]['location'] =~ /^#{dl_target}/
          raise InvalidLocationProperty, 'SUMA-SUMA-SUMA lpp source location mismatch'
        end
      end
    elsif location.empty?
      dl_target = "/usr/sys/inst.images/#{lpp_source}"
    else
      begin
        dl_target = node['nim']['lpp_sources'].fetch(location).fetch('location')
        Chef::Log.info("Discover \'#{location}\' lpp source's location: \'#{dl_target}\'")
      rescue Exception => e
        raise InvalidLocationProperty, "SUMA-SUMA-SUMA cannot find lpp_source \'#{location}\' from Ohai output"
      end
    end
  else
    dl_target = "/usr/sys/inst.images/#{lpp_source}"
  end
  dl_target
end

load_current_value do
end

action :download do
  # inputs
  Chef::Log.info("desc=\"#{desc}\"")
  Chef::Log.info("oslevel=\"#{oslevel}\"")
  Chef::Log.info("location=\"#{location}\"")
  Chef::Log.info("targets=\"#{targets}\"")
  Chef::Log.info("tmp_dir=\"#{tmp_dir}\"")

  # compute suma request type based on oslevel property
  rq_type = compute_rq_type
  Chef::Log.info("rq_type=#{rq_type}")

  # compute suma filter ml based on oslevel and targets property
  filter_ml = compute_filter_ml(rq_type)
  Chef::Log.info("filter_ml=#{filter_ml}")

  # compute suma request name based on metadata info
  rq_name = compute_rq_name(rq_type, filter_ml)
  Chef::Log.info("rq_name=#{rq_name}")

  # compute lpp source name based on request name
  lpp_source = compute_lpp_source_name(rq_name)
  Chef::Log.info("lpp_source=#{lpp_source}")

  # compute dl target based on lpp source name
  dl_target = compute_dl_target(lpp_source)
  Chef::Log.info("dl_target=#{dl_target}")

  # create directory
  unless ::File.directory?(dl_target.to_s)
    shell_out!("mkdir -p #{dl_target}")
    Chef::Log.warn("Directory \'#{dl_target}\' has been created")
  end

  # suma preview
  suma_s = "/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a RqType=#{rq_type} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  case rq_type
  when 'SP'
    suma_s << " -a RqName=#{rq_name}"
  when 'TL'
    suma_s << " -a RqName=#{rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
  end
  preview_dl = 0
  preview_downloaded = 0
  preview_failed = 0
  preview_skipped = 0
  suma_preview_s = "#{suma_s} -a Action=Preview"
  Chef::Log.info("SUMA preview operation: #{suma_preview_s}")
  so = shell_out(suma_preview_s, environment: { 'LANG' => 'C' })
  if so.error?
    if so.stderr =~ /0500-035 No fixes match your query./
      Chef::Log.info("SUMA-SUMA-SUMA error:\n#{so.stderr.chomp!}")
    else
      raise SumaPreviewError, "SUMA-SUMA-SUMA error:\n#{so.stderr.chomp!}"
    end
  else
    Chef::Log.warn("Done suma preview operation \"#{suma_preview_s}\"")
    Chef::Log.info(so.stdout.to_s)
    if so.stdout =~ /([0-9]+) downloaded.*?([0-9]+) failed.*?([0-9]+) skipped/m
      preview_downloaded = Regexp.last_match(1)
      preview_failed = Regexp.last_match(2)
      preview_skipped = Regexp.last_match(3)
      Chef::Log.info("#{preview_downloaded} downloaded, #{preview_failed} failed, #{preview_skipped} skipped fixes")
      preview_dl = so.stdout.match(/Total bytes of updates downloaded: ([0-9]+)/)[1].to_f / 1024 / 1024 / 1024
    end
  end

  unless preview_dl.to_f == 0
    succeeded = 0
    failed = 0
    skipped = 0
    # suma download
    suma_download_s = "#{suma_s} -a Action=Download"
    converge_by("suma download operation: \"#{suma_download_s}\"") do
      # timeout=600+dl.to_f*600  # 10 min + 10 min / GB
      Chef::Log.warn("Start downloading #{preview_downloaded} fixes (~ #{preview_dl.to_f.round(2)} GB) to \'#{dl_target}\' directory.") # It may take up to #{Time.at(timeout).utc.strftime("%Hh:%Mm:%Ss")}.")
      # so=shell_out!(suma_download_s, :timeout => timeout.to_i)
      download_downloaded = 0
      download_failed = 0
      download_skipped = 0
      exit_status = Open3.popen3(suma_download_s) do |stdin, stdout, stderr, wait_thr|
        stdin.close
        stdout.each_line do |line|
          if line =~ /^Download SUCCEEDED:/
            succeeded += 1
          elsif line =~ /^Download FAILED:/
            failed += 1
          elsif line =~ /^Download SKIPPED:/
            skipped += 1
          elsif line =~ /([0-9]+) downloaded/
            download_downloaded = Regexp.last_match(1)
          elsif line =~ /([0-9]+) failed/
            download_failed = Regexp.last_match(1)
          elsif line =~ /([0-9]+) skipped/
            download_skipped = Regexp.last_match(1)
          elsif line =~ /(Total bytes of updates downloaded|Summary|Partition id)/
            # do nothing
          else
            puts line
          end
          print "\rSUCCEEDED: #{succeeded}/#{preview_downloaded}\tFAILED: #{failed}/#{preview_failed}\tSKIPPED: #{skipped}/#{preview_skipped}"
        end
        puts ''
        stdout.close
        stderr.each_line do |line|
          puts line
        end
        stderr.close
        wait_thr.value # Process::Status object returned.
      end
      Chef::Log.warn("Finish downloading #{succeeded} fixes.")
      unless exit_status.success?
        raise SumaDownloadError, "SUMA-SUMA-SUMA error:\n#{so.stderr.chomp!}"
      end
    end

    if failed.to_i == 0 && node['nim']['lpp_sources'].fetch(lpp_source, nil).nil?
      # nim define
      nim_s = "nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{lpp_source}"
      Chef::Log.info("NIM operation: #{nim_s}")
      converge_by("nim define lpp_source: \"#{nim_s}\"") do
        Chef::Log.info("Define #{lpp_source} ...")
        so = shell_out!(nim_s)
      end
    end

  end
end
