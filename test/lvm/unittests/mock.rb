#
# Copyright 2016, International Business Machines Corporation
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
#

require_relative '../../../libraries/tools'

class MockSystem < AIXLVM::BaseSystem
  def initialize
    @out_retrun = []
    @cmd_add = []
  end

  def add_retrun(cmd, value)
    @out_retrun.push([cmd, value])
  end

  def get_cmd
    @cmd_add
  end

  def residual
    res = ''
    for val in @out_retrun
      res += "%s => %s\n" % val
    end
    res
  end

  def run(cmd)
    @cmd_add.push(cmd)
    expected_cmd, retvalue = @out_retrun.shift
    if expected_cmd != cmd
      raise AIXLVM::LVMException, "System command error:'%s' expected, '%s' return!" % [expected_cmd, cmd]
    end
    @last_error = cmd if retvalue.nil?
    retvalue
  end
end
