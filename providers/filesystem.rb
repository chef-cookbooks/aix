# Author:: IBM Corporation
# Cookbook Name:: aix
# Provider:: filesystem
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

# Support whyrun
def whyrun_supported?
  true
end

def load_current_resource
  @filesystem = AIXLVM::FileSystem.new(@new_resource.name, AIXLVM::System.new)
  @filesystem.logical_volume = @new_resource.logical
  @filesystem.size = @new_resource.size
end

action :create do
  begin
    if @filesystem.check_to_change
      converge_by(@filesystem.create.join(' | ')) do
      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

action :mount do
  begin
    if @filesystem.check_to_mount(true)
      converge_by(@filesystem.mount.join(' | ')) do
      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

action :umount do
  begin
    if @filesystem.check_to_mount(false)
      converge_by(@filesystem.umount.join(' | ')) do
      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end

action :defragfs do
  begin
    if @filesystem.check_to_defrag
      converge_by(@filesystem.defragfs.join(' | ')) do
      end
    end
  rescue AIXLVM::LVMException => e
    Chef::Log.fatal(e.message)
  end
end
