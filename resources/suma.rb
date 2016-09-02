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
property :location, String, default: "/usr/sys/inst.images"
property :targets, String

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
    else
      raise "SUMA-SUMA-SUMA oslevel is not recognized!"
    end
  else
    rq_type="Latest"
    rq_name='9999-99-99-9999' # TODO find latest SP for highest TL (with METADATA)
    rq_name=rq_name.match(/^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/)[1]
  end
  Chef::Log.info("rq_type=#{rq_type}")
  Chef::Log.info("rq_name=#{rq_name}")

        #
		# TODO warn if 7.2 and 7.1: "release level mismatch. Took the highest."
		#

  # find lowest ML level by comparing each machine's oslevel from ohai
  filter_ml=nil
  if property_is_set?(:targets)

    # get list of all NIM machines from Ohai
    all_machines=node['nim']['clients'].keys
    Chef::Log.info("Ohai client machine's list is #{all_machines}")

    # build machine list by expanding wildcard
	selected_machines=Array.new
    targets.split(',').each do |machine|
	  if machine.match(/\*/)
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
	selected_machines.sort.uniq!
    Chef::Log.info "List of targets expanded to #{selected_machines}"

	# build machine-oslevel hash
    hash=Hash[selected_machines.collect do |m|
      begin
	    filter_ml=node['nim']['clients'][m].fetch('oslevel')
        Chef::Log.info("Obtained OS level for machine #{m}: #{filter_ml}")
		filter_ml=filter_ml.match(/^([0-9]{4}-[0-9]{2})(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1]
        [ m, filter_ml.delete('-') ]
      rescue Exception => e
        Chef::Log.warn("Cannot find OS level for machine #{m} into Ohai output")
        [ m, nil ]
	  end
	end ]
    Chef::Log.info "hash=#{hash}"

    if rq_type.eql?("Latest")
      # find highest
      filter_ml=hash.values.max
    else
      # find lowest
      filter_ml=hash.values.min
    end

  end
  if filter_ml.nil?
    raise "SUMA-SUMA-SUMA no client targets specified or cannot reach them all!"
  end
  filter_ml.insert(4, '-')
  Chef::Log.info("Filter ML level is: #{filter_ml}")

  # create location if it does not exist
  res_name="#{rq_name}-lpp_source"
  dl_target="#{location}/#{res_name}"
  unless ::File.directory?("#{dl_target}")
    Chef::Log.info("Creating location #{dl_target}...")
    shell_out!("mkdir -p #{dl_target}")
	Chef::Log.warn("Directory #{dl_target} has been created.")
  end

  # suma preview
  suma_s="suma -x -a DisplayName=\"#{desc}\" -a RqType=#{rq_type} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  unless rq_type.eql?("Latest")
    suma_s << " -a RqName=#{rq_name}"
  end
  dl=0
  Chef::Log.info("SUMA preview operation: #{suma_s}")
  so=shell_out("LANG=C #{suma_s} -a Action=Preview 2>&1")
  if so.error?
    if so.stdout =~ /0500-035 No fixes match your query./
      Chef::Log.info("Suma error: No fixes match your query")
    else
      raise "SUMA-SUMA-SUMA error:\n#{so.stdout}"
    end
  else
    Chef::Log.info("#{so.stdout}")
    if so.stdout =~ /Total bytes of updates downloaded: ([0-9]+)/
      dl=$1.to_f/1024/1024/1024
      Chef::Log.info("#{dl.to_f.round(2)} GB to download")
    end
    if so.stdout =~ /([0-9]+) failed/
      failed=$1
      Chef::Log.info("#{failed} failed fixes")
    end
  end

  unless dl.to_f == 0
    # suma download
    converge_by("suma download operation: \"#{suma_s}\"") do
	  timeout=600+dl.to_f*900  # 10 min + 15 min / GB
      Chef::Log.info("Download fixes with #{timeout.to_i}s timeout...")
      so=shell_out!("#{suma_s} -a Action=Download 2>&1", :timeout => timeout.to_i)
    end

	unless failed.to_i > 0 or node['nim']['lpp_sources'].fetch(res_name, nil) == nil
      # nim define
      nim_s="nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{res_name}"
      converge_by("nim define lpp_source: \"#{nim_s}\"") do
        Chef::Log.info("Define #{res_name} ...")
        so=shell_out!("#{nim_s}")
      end
	end

  end

end
