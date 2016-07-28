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

actions :update
default_action :update

attr_accessor :exists

attribute :location, kind_of: String, default: "/usr/sys/inst.images"
attribute :target, kind_of: String, default: ""
attribute :server, kind_of: String, default: "master"

# nim / niminv reminder
# nim -o define -t lpp_source [ -a Field=Value ]... <ident>
# nim -o cust [ -a Field=Value ]... <client>
# niminv -o invcmp [ -a Field=Value ]
