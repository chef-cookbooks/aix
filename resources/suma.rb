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

actions :download
default_action :download

attr_accessor :exists

attribute :rq_type, kind_of: String, default: 'Latest'
attribute :rq_name, kind_of: String, default: ''
attribute :dl_target, kind_of: String, default: '/usr/sys/inst.images'
attribute :filter_ml, kind_of: String, default: ''

# suma reminder
# suma -c [ -a Field=Value ]...
# suma -x [ -a Field=Value ]...
# suma -s CronSched [ -a Field=Value ]...
# suma -d TaskID
