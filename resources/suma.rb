# Author:: IBM Corporation
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
property :tmp_dir, String

load_current_value do
end

action :download do

  # inputs
  puts ""
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("oslevel=\"#{oslevel}\"")
  Chef::Log.debug("location=\"#{location}\"")
  Chef::Log.debug("targets=\"#{targets}\"")
  Chef::Log.debug("tmp_dir=\"#{tmp_dir}\"")

  check_ohai

  # compute suma filter ml based on oslevel and targets property
  filter_ml=compute_filter_ml
  Chef::Log.debug("filter_ml=#{filter_ml}")

  # compute suma request type based on oslevel property
  rq_type=compute_rq_type
  Chef::Log.debug("rq_type=#{rq_type}")

  # compute suma request name based on metadata info
  rq_name=compute_rq_name(rq_type)
  Chef::Log.debug("rq_name=#{rq_name}")

  # compute lpp source name based on request name
  lpp_source=compute_lpp_source_name(rq_name)
  Chef::Log.debug("lpp_source=#{lpp_source}")

  # compute suma dl target based on lpp source name
  dl_target=compute_dl_target(lpp_source)
  Chef::Log.debug("dl_target=#{dl_target}")

  # create directory
  unless ::File.directory?("#{dl_target}")
    mkdir_s="mkdir -p #{dl_target}"
	converge_by("create directory \'#{dl_target}\'") do
      shell_out!(mkdir_s)
	end
  end

  # suma preview
  suma_s="/usr/sbin/suma -x -a DisplayName=\"#{desc}\" -a RqType=#{rq_type} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  case rq_type
  when 'SP'
    suma_s << " -a RqName=#{rq_name}"
  when 'TL'
    suma_s << " -a RqName=#{rq_name.match(/^([0-9]{4}-[0-9]{2})-00-0000$/)[1]}"
  end
  preview_dl=0
  preview_downloaded=0
  preview_failed=0
  preview_skipped=0
  suma_preview_s="#{suma_s} -a Action=Preview"
  Chef::Log.debug("SUMA preview operation: #{suma_preview_s}")
  so=shell_out(suma_preview_s, :environment => { "LANG" => "C" })
  if so.error?
    if so.stderr =~ /^0500-035 No fixes match your query.$/
      Chef::Log.info("SUMA-SUMA-SUMA error:\n#{so.stderr.chomp!}")
      Chef::Log.warn("Done suma preview operation \"#{suma_preview_s}\"")
    else
      raise SumaPreviewError, "Error:\n#{so.stderr.chomp!}"
    end
  else
    Chef::Log.warn("Done suma preview operation \"#{suma_preview_s}\"")
    Chef::Log.info("#{so.stdout}")
    if so.stdout =~ /([0-9]+) downloaded.*?([0-9]+) failed.*?([0-9]+) skipped/m
      preview_downloaded=$1
	  preview_failed=$2
	  preview_skipped=$3
      Chef::Log.info("#{preview_downloaded} downloaded, #{preview_failed} failed, #{preview_skipped} skipped fixes")
      preview_dl=so.stdout.match(/Total bytes of updates downloaded: ([0-9]+)/)[1].to_f/1024/1024/1024
    end
  end

  unless preview_dl.to_f == 0
    succeeded=0
    failed=0
    skipped=0
    # suma download
	suma_download_s="#{suma_s} -a Action=Download"
    converge_by("suma download operation: \"#{suma_download_s}\"") do
      Chef::Log.warn("Start downloading #{preview_downloaded} fixes (~ #{preview_dl.to_f.round(2)} GB) to \'#{dl_target}\' directory.")
      #start=Time.now
      download_downloaded=0
      download_failed=0
      download_skipped=0
	  exit_status=Open3.popen3(suma_download_s) do |stdin, stdout, stderr, wait_thr|
        stdin.close
        stdout.each_line do |line|
          if line =~ /^Download SUCCEEDED:/
            succeeded+=1
          elsif line =~ /^Download FAILED:/
            failed+=1
          elsif line =~ /^Download SKIPPED:/
            skipped+=1
          elsif line =~ /([0-9]+) downloaded/
            download_downloaded=$1
		  elsif line =~ /([0-9]+) failed/
            download_failed=$1
		  elsif line =~ /([0-9]+) skipped/
            download_skipped=$1
          elsif line =~ /(Total bytes of updates downloaded|Summary|Partition id|Filesystem size changed to)/
            # do nothing
          else
            puts "\n#{line}"
		  end
          #time_s=(Time.now-start).duration
		  print "\rSUCCEEDED: #{succeeded}/#{preview_downloaded}\tFAILED: #{failed}/#{preview_failed}\tSKIPPED: #{skipped}/#{preview_skipped}" #.  (Total time: #{time_s})."
		  stdout.flush
        end
		puts ""
        stdout.close
        stderr.each_line do |line|
          puts line
        end
		stderr.close
		wait_thr.value # Process::Status object returned.
      end
      Chef::Log.warn("Finish downloading #{succeeded} fixes.")
      unless exit_status.success?
        raise SumaDownloadError, "Error: cannot downloading fixes"
      end
	  
    end

	# create nim lpp source
    if failed == 0 and node['nim']['lpp_sources'].fetch(lpp_source, nil) == nil
      nim_s="nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{lpp_source}"
      Chef::Log.debug("NIM operation: #{nim_s}")
      converge_by("create nim lpp source \'#{lpp_source}\'") do
        so=shell_out(nim_s)
        if so.error?
          raise NimDefineError, "Error: cannot define lpp source.\n#{so.stderr.chomp!}"
        end
      end
    end

  end

end
