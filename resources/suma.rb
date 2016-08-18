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

property :name, String, name_property: true
property :rq_type, String, default: 'Latest'
property :rq_name, String
property :dl_target, String
property :filter_ml, String
property :filter_dir, String

# suma reminder
# suma -c [ -a Field=Value ]...
# suma -x [ -a Field=Value ]...
# suma -s CronSched [ -a Field=Value ]...
# suma -d TaskID

load_current_value do

end
	
action :download do
  # Example of suma 
  # suma -x -a Action=Download -a RqType=Latest -a DLTarget=/home/toto -a FilterML=6100-01 -a FilterDir=/usr/sys/inst.images
  # suma -x -a Action=Download -a RqType=SP -a RqName=6100-01-08 -a DLTarget=/home/toto -a FilterML=6100-01 -a FilterDir=/usr/sys/inst.images
  # suma -x -a Action=Download -a RqType=TL -a RqName=6100-02 -a DLTarget=/home/toto -a FilterML=6100-01 -a FilterDir=/usr/sys/inst.images
  
  suma_s = 'suma -x'

  # getting display name
  suma_s = suma_s << ' -a DisplayName="' << name << '"'
  
  # getting rq_type or use default (allowed: Latest, SP, TL)
  suma_s = suma_s << ' -a RqType=' << rq_type

  # getting rq_name
  if property_is_set?(:rq_name)
    unless rq_type == 'Latest'
      suma_s = suma_s << ' -a RqName=' << rq_name
    end
  end

  # getting dl_target
  if property_is_set?(:dl_target)
    # create if not already created
    directory dl_target do
      recursive true
	  action :create
    end

    suma_s = suma_s << ' -a DLTarget=' << dl_target 
  end

  # getting filter_ml
  if property_is_set?(:filter_ml)
    suma_s = suma_s << ' -a FilterML=' << filter_ml
  end

  # getting filter_dir
  if property_is_set?(:filter_dir)
    suma_s = suma_s << ' -a FilterDir=' << filter_dir
  end

  
  #available_space=shell_out("df -g #{dl_target} | tail -n 1 | tr -s ' ' | cut -d' ' -f3").stdout
  #needed_space=shell_out("echo \"scale=2; `#{suma_s} -a Action=Preview | grep \\"Total bytes of updates downloaded:\\" | cut -d' ' -f6`/1024/1024/1024\" | bc").stdout
  
  begin
    # command to run is build here
    so = shell_out!("#{suma_s} -a Action=Preview")
	#puts so
	dl = shell_out("echo \"#{so.stdout}\" | grep \"Total bytes of updates downloaded:\" | cut -d' ' -f6").stdout
	
	unless dl == 0
	  converge_by("suma download operation: \"#{suma_s}\"") do
        suma = Mixlib::ShellOut.new(suma_s)
        suma.valid_exit_codes = 0
        suma.run_command
        suma.error!
        suma.error?
	  end
    end
  
  rescue Mixlib::ShellOut::ShellCommandFailed => e
    Chef::Log.fatal(e.message)
  end
  
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
