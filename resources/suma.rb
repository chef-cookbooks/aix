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

actions :config, :run, :deleteall, :schedule
default_action :run

attr_accessor :exists

attribute :dl_timeout_sec, kind_of: Integer, default: 180
attribute :download_protocol, kind_of: String, default: 'http'
attribute :screen_verbose, kind_of: String, default: 'LVL_INFO'
attribute :notify_verbose, kind_of: String, default: 'LVL_INFO'
attribute :logfile_verbose, kind_of: String, default: 'LVL_VERBOSE'
attribute :maxlogsize_mb, kind_of: Integer, default: 1
attribute :remove_conflicting_updates, kind_of: [TrueClass, FalseClass], default: true
attribute :remove_dup_base_levels, kind_of: [TrueClass, FalseClass], default: true
attribute :remove_supersede, kind_of: [TrueClass, FalseClass], default: true
attribute :tmpdir, kind_of: String, default: '/var/suma/tmp'

attribute :rq_type, kind_of: String, default: 'Latest'
attribute :rq_name, kind_of: String, default: ''
attribute :suma_action, kind_of: String, default: 'Download'
attribute :dl_target, kind_of: String, default: '/usr/sys/inst.images'
attribute :notify_email, kind_of: String, default: ''
attribute :filter_dir, kind_of: String, default: ''
attribute :filter_ml, kind_of: String, default: ''
attribute :max_dl_size, kind_of: Integer, default: -1
attribute :extend, kind_of: [TrueClass, FalseClass], default: true
attribute :max_fs_size, kind_of: Integer, default: -1


# suma reminder
# suma -c [ -a Field=Value ]...
# suma -x [ -a Field=Value ]...
# suma -s CronSched [ -a Field=Value ]...
# suma -d TaskID
