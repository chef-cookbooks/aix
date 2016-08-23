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
property :name, String
property :location, String, default: "/usr/sys/inst.images"
property :targets, String

load_current_value do
end

action :download do

  Chef::Log.info("name=#{name}")
  Chef::Log.info("location=#{location}")
  Chef::Log.info("targets=#{targets}")

  machines=targets.split(',')
  Chef::Log.info("machines=#{machines}")

  # find lowest ML level by comparing each machine's oslevel
  filter_ml='7200-00'
  filter_ml.delete!('-')
  machines.each do |machine|

    new_filter_ml = shell_out!("/usr/lpp/bos.sysmgt/nim/methods/c_rsh #{machine} \"/usr/bin/oslevel -r\"").stdout.chomp!
    Chef::Log.info("Obtained ML level for machine #{machine}: #{new_filter_ml}")

	new_filter_ml.delete!('-')
	old_filter_ml=new_filter_ml
	if new_filter_ml <= old_filter_ml
	  filter_ml=new_filter_ml
	end

  end
  filter_ml.insert(4, '-')
  Chef::Log.info("Lowest ML level is: #{filter_ml}")

  # create location if it does not exist
  dl_target="#{location}/#{name}-lpp_source"
  Chef::Log.info("Checking location #{dl_target}...")
  directory dl_target do
    recursive true
    action :create
  end

  suma_s="suma -x -a DisplayName=#{desc} -a RqType=SP -a RqName=#{name} -a DLTarget=#{dl_target} -a FilterML=#{filter_ml}"
  res_name="#{name}-lpp_source"

  # suma preview
  dl=0
  Chef::Log.info("Preview operation...")
  so=shell_out("#{suma_s} -a Action=Preview 2>&1")
  #raise "no: #{suma_s} -a Action=Preview failed" if so.exitstatus != 0
  if so.error?
	Chef::Log.info("suma returns an error...")
    need=shell_out!("echo \"#{so.stdout}\" | grep \"0500-035 No fixes match your query.\"")
    if need.error?
	  Chef::Log.info("Other suma error")
	else
	  Chef::Log.info("Suma error: No fixes match your query")
	end
  else
	dl=shell_out("echo \"#{so.stdout}\" | grep \"Total bytes of updates downloaded:\" | cut -d' ' -f6").stdout
	if dl == 0
	  Chef::Log.info("Nothing to download")
	else
      Chef::Log.info("Something to download")
    end
  end

  unless dl == 0 
    # suma download
    converge_by("suma download operation: \"#{suma_s}\"") do
      Chef::Log.info("Download fixes...")
      so=shell_out("#{suma_s} -a Action=Download 2>&1")
    end

    # nim define
    Chef::Log.info("Define #{res_name} ...")
    so=shell_out("nim -o define -t lpp_source -a server=master -a location=#{dl_target} #{res_name}")
  end

  #rescue Mixlib::ShellOut::ShellCommandFailed => e
  #  Chef::Log.fatal(e.message)
  #end
  
  # converge here
  #unless do_not_converge
  #  converge_by("suma download operation: \"#{suma_s}\"") do
  #    suma = Mixlib::ShellOut.new(suma_s, timeout: 7200)
  #    suma.valid_exit_codes = 0
  #    suma.run_command
  #    suma.error!
  #    suma.error?
  #  end
  #end
end
