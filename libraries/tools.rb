#
# Copyright:: 2016, International Business Machines Corporation
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

require 'open3'

module AIXLVM
  class LVMException < Exception
  end

  class BaseSystem
    attr_reader :last_error
    def initialize
      @last_error = ''
    end

    def run(_cmd)
      raise 'Abstract!'
    end
  end

  class System < BaseSystem
    def run(cmd)
      stdout, @last_error, status = Open3.capture3({ 'LANG' => 'C' }, *cmd)
      if status.success?
        return stdout.slice!(0..-(1 + $/.size))
      else
        return nil
      end
    rescue
      return nil
    end
  end
end
