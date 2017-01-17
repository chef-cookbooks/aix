#
# Copyright 2014-2016, Chef Software, Inc.
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

use_inline_resources

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @current_resource = Chef::Resource::AixTcpservice.new(@new_resource.name)

  so = shell_out("egrep '^start /usr/(sbin|lib)/#{@new_resource.identifier}' /etc/rc.tcpip")
  @current_resource.enabled = so.exitstatus.zero?
end

action :enable do
  immediate = '-S ' if @new_resource.immediate
  unless @current_resource.enabled
    converge_by('enable TCP/IP service') do
      shell_out("chrctcp #{immediate}-a #{@new_resource.identifier}")
    end
  end
end

action :disable do
  immediate = '-S ' if @new_resource.immediate
  if @current_resource.enabled
    converge_by('disable TCP/IP service') do
      shell_out("chrctcp #{immediate}-d #{@new_resource.identifier}")
    end
  end
end
