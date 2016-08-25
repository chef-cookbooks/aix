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

property :desc, [String,nil], name_property: true
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
    if oslevel =~ /^([0-9]{4}-[0-9]{2})(|-00|-00-[0-9]{4})$/ then
      rq_type="TL"
      rq_name=$1
    else
      if oslevel =~ /^([0-9]{4}-[0-9]{2}-[0-9]{2})(|-[0-9]{4})$/ then
        rq_type="SP"
        rq_name=$1
      else
        raise "SUMA-SUMA-SUMA oslevel is not recognized!"
      end
    end
  else
    rq_type="Latest"
  end
  Chef::Log.info("rq_type=#{rq_type}")
  Chef::Log.info("rq_name=#{rq_name}")
  
  # find lowest ML level by comparing each machine's oslevel from ohai
  last_ml_level='7200-00'    # TODO: GET LAST ML LEVEL (WITH METADATA ?)
  filter_ml=last_ml_level
  filter_ml.delete!('-')
  if property_is_set?(:targets)
    machines=targets.split(',')
    Chef::Log.info("machines=#{machines}")
	new_filter_ml=String.new
	old_filter_ml=String.new
    machines.each do |machine|

	  begin
        old_filter_ml=new_filter_ml
        new_filter_ml=String.new(node.fetch('nim', {}).fetch('clients', {}).fetch(machine, {}).fetch('mllevel'))
	    Chef::Log.info("Obtained ML level for machine #{machine}: #{new_filter_ml}")
		Chef::Log.info("#{node.fetch('nim', {}).fetch('clients', {}).fetch(machine, {}).fetch('mllevel')}")
        new_filter_ml.delete!('-')
        if new_filter_ml.to_i <= old_filter_ml.to_i
          filter_ml=new_filter_ml
        end
	  rescue Exception => e
        puts e.message
        puts e.backtrace.inspect
	  end

    end
  else
    raise "SUMA-SUMA-SUMA no client targets specified!"
  end
  filter_ml.insert(4, '-')
  Chef::Log.info("Lowest ML level is: #{filter_ml}")

  # create location if it does not exist
  if rq_name.nil?
    res_name="#{last_ml_level}-lpp_source"
  else
    res_name="#{rq_name}-lpp_source"
  end
  dl_target="#{location}/#{res_name}"
  Chef::Log.info("Checking location #{dl_target}...")
  shell_out!("mkdir -p #{dl_target}")

  # suma preview
  suma_s="suma -x -a DisplayName=\"#{desc}\" -a RqType=#{rq_type} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  unless rq_name.nil?
	suma_s << " -a RqName=#{rq_name}"
  end
  dl=0
  Chef::Log.info("SUMA preview operation: #{suma_s}")
  so=shell_out("#{suma_s} -a Action=Preview 2>&1")
  if so.error?
    Chef::Log.info("suma returns an error...")
    need=shell_out!("echo \"#{so.stdout}\" | grep \"0500-035 No fixes match your query.\"")
    if need.error?
      Chef::Log.info("Other suma error")
    else
      Chef::Log.info("Suma error: No fixes match your query")
    end
  else
    dl=shell_out("scale=2; `echo \"#{so.stdout}\" | grep \"Total bytes of updates downloaded:\" | cut -d' ' -f6`/1024/1024/1024\" | bc").stdout.strip.to_f
    if dl == 0
      Chef::Log.info("Nothing to download")
    else
      Chef::Log.info("#{dl} GB to download")
    end
    failed=shell_out("echo \"#{so.stdout}\" | grep \"failed\" | cut -d' ' -f1").stdout.strip.to_i
    if failed > 0
      Chef::Log.info("#{failed} failed fixes")
    else
      Chef::Log.info("No failed fixes")
    end
  end

  unless dl == 0 or failed > 0
    # suma download
    converge_by("suma download operation: \"#{suma_s}\"") do
      Chef::Log.info("Download fixes...")
      so=shell_out("#{suma_s} -a Action=Download 2>&1")
    end

    # nim define
    converge_by("nim define lpp_source: \"#{res_name}\"") do
      Chef::Log.info("Define #{res_name} ...")
      so=shell_out("nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{res_name}")
    end
  end

end
