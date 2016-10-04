#
# Copyright 2016, International Business Machines Corporation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include AIX::PatchMgmt

property :desc, String, name_property: true
property :oslevel, String
property :location, String
property :targets, String
property :tmp_dir, String

default_action :download

load_current_value do
end

action :download do
  # inputs
  Chef::Log.debug("desc=\"#{desc}\"")
  Chef::Log.debug("oslevel=\"#{oslevel}\"")
  Chef::Log.debug("location=\"#{location}\"")
  Chef::Log.debug("targets=\"#{targets}\"")
  Chef::Log.debug("tmp_dir=\"#{tmp_dir}\"")

  # check ohai nim info
  check_ohai

  # build list of targets
  target_list = expand_targets
  Chef::Log.debug("target_list=#{target_list}")

  # compute suma request type based on oslevel property
  rq_type = compute_rq_type
  Chef::Log.debug("rq_type=#{rq_type}")

  # compute suma filter ml based on targets property
  filter_ml = compute_filter_ml(target_list)
  Chef::Log.debug("filter_ml=#{filter_ml}")

  # check ml level of machines against expected oslevel
  case rq_type
  when 'SP', 'TL'
    if filter_ml[0..3].to_i < oslevel.match(/^([0-9]{4})-[0-9]{2}(|-[0-9]{2}|-[0-9]{2}-[0-9]{4})$/)[1].to_i
      raise InvalidOsLevelProperty, 'Error: cannot upgrade machines to a new release using suma'
    end
  end

  # compute suma request name based on metadata info
  rq_name = compute_rq_name(rq_type, target_list)
  Chef::Log.debug("rq_name=#{rq_name}")

  # compute lpp source name based on request name
  lpp_source = compute_lpp_source_name(rq_name)
  Chef::Log.debug("lpp_source=#{lpp_source}")

  # compute suma dl target based on lpp source name
  dl_target = compute_dl_target(lpp_source)
  Chef::Log.debug("dl_target=#{dl_target}")

  # create directory
  unless ::File.directory?(dl_target)
    mkdir_s = "mkdir -p #{dl_target}"
    converge_by("create directory \'#{dl_target}\'") do
      shell_out!(mkdir_s)
    end
  end

  # suma preview
  suma = Suma.new(desc, rq_type, rq_name, filter_ml, dl_target)
  suma.preview

  if suma.dl.to_f > 0
    # suma download
    converge_by("download #{suma.downloaded} fixes") do
      suma.download
    end

    # create nim lpp source
    if suma.failed.to_i == 0 && node['nim']['lpp_sources'].fetch(lpp_source, nil).nil?
      nim = Nim.new
      converge_by("define nim lpp source \'#{lpp_source}\'") do
        nim.define_lpp_source(lpp_source, dl_target)
      end
    end
  end
end
