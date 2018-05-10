#
# Copyright:: 2015-2016, Benoit Creau <benoit.creau@chmod666.org>
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
  @current_resource = new_resource.class.new(@new_resource.name)

  # we assume nim client is configured if niminfo exists ...
  # Idea, checking if nimsh running will tell us its runs but we can't get config this way
  # I don't know if there is a better way to do this
  @current_resource.exists = ::File.exist?('/etc/niminfo')
end

action :setup do
  # setup niminit if the resource does not exists
  unless @current_resource.exists
    converge_by('niminit: niminiting client') do
      # Example of niminiting
      # niminit -a name=s00va9940871 -a master=nimprod -a pif_name=en0 -a connect=nimsh
      master = @new_resource.master
      name = @new_resource.name
      pif_name = @new_resource.pif_name
      connect = @new_resource.connect
      niminit_s = 'niminit -a master=' << master << ' -a name=' << name << ' -a pif_name=' << pif_name << ' -a connect=' << connect
      Chef::Log.debug("niminit: running #{niminit_s}")
      shell_out!(niminit_s)
    end
  end
end

action :remove do
  # removing nimclient configuration only if the resource exists
  if @current_resource.exists
    converge_by('niminit: removing nimclient configuration') do
      stopsrc_s = 'stopsrc -g nimclient'
      Chef::Log.debug("niminit: stoping nimclient running #{stopsrc_s}")
      shell_out(stopsrc_s)
      # we don't care here about return code, sometime nimsh will not be runing
      # removing /etc/niminfo
      Chef::Log.debug('niminit: removing /etc/niminfo')
      ::File.delete('/etc/niminfo')
    end
  end
end
