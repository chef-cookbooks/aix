# Author:: Jérôme Hurstel (<jerome.hurstel@atos.ne>) & Laurent Gay (<laurent.gay@atos.net>)
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

property :desc, String, name_property: true
property :name, String
property :targets, String

load_current_value do

end

action :update do

  res_name="#{name}-lpp_source"
  nim_s="nim -o cust -a lpp_source=#{res_name} #{targets.gsub!(',', ' ')}"

  unless shell_out("lsnim -t lpp_source #{res_name}").error?
    # nim install
    converge_by("nim custom operation: \"#{nim_s}\"") do
      Chef::Log.info("Install fixes...")
      so=shell_out!("#{nim_s}")
    end
  end

end
