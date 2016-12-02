#
# Copyright:: 2016, Noah Kantrowitz
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

if defined?(ChefSpec)
  # Matchers for aix_bootlist.
  def update_aix_bootlist(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_bootlist, :update, resource_name)
  end

  def invalidate_aix_bootlist(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_bootlist, :invalidate, resource_name)
  end

  # Matchers for aix_chdev.
  def update_aix_chdev(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_chdev, :update, resource_name)
  end

  # Matchers for aix_altdisk.
  def create_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :create, resource_name)
  end

  def cleanup_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :cleanup, resource_name)
  end

  def rename_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :rename, resource_name)
  end

  def wakeup_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :wakeup, resource_name)
  end

  def sleep_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :sleep, resource_name)
  end

  def customize_aix_altdisk(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_altdisk, :customize, resource_name)
  end

  # Matchers for aix_chsec.
  def update_aix_chsec(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_chsec, :update, resource_name)
  end

  # Matchers for aix_etchosts.
  def add_aix_etchosts(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_etchosts, :add, resource_name)
  end

  def delete_aix_etchosts(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_etchosts, :delete, resource_name)
  end

  def delete_all_aix_etchosts(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_etchosts, :delete_all, resource_name)
  end

  def change_aix_etchosts(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_etchosts, :change, resource_name)
  end

  # Matchers for aix_filesystem.
  def create_aix_filesystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_filesystem, :create, resource_name)
  end

  def mount_aix_filesystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_filesystem, :mount, resource_name)
  end

  def umount_aix_filesystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_filesystem, :umount, resource_name)
  end

  def defragfs_aix_filesystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_filesystem, :defragfs, resource_name)
  end

  # Matchers for aix_fixes.
  def install_aix_fixes(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_fixes, :install, resource_name)
  end

  def remove_aix_fixes(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_fixes, :remove, resource_name)
  end

  # Matchers for aix_logical_volume.
  def create_aix_logical_volume(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_logical_volume, :create, resource_name)
  end

  # Matchers for aix_inittab.
  def install_aix_inittab(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_inittab, :install, resource_name)
  end

  def remove_aix_inittab(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_inittab, :remove, resource_name)
  end

  # Matchers for aix_multibos.
  def create_aix_multibos(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_multibos, :create, resource_name)
  end

  def remove_aix_multibos(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_multibos, :remove, resource_name)
  end

  def update_aix_multibos(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_multibos, :update, resource_name)
  end

  def mount_aix_multibos(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_multibos, :mount, resource_name)
  end

  def umount_aix_multibos(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_multibos, :umount, resource_name)
  end

  # Matchers for aix_nimclient.
  def allocate_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :allocate, resource_name)
  end

  def deallocate_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :deallocate, resource_name)
  end

  def cust_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :cust, resource_name)
  end

  def enable_push_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :enable_push, resource_name)
  end

  def disable_push_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :disable_push, resource_name)
  end

  def set_date_aix_nimclient(resource_name) # rubocop:disable Style/AccessorMethodName
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :set_date, resource_name)
  end

  def enable_crypto_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :enable_crypto, resource_name)
  end

  def disable_crypto_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :disable_crypto, resource_name)
  end

  def reset_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :reset, resource_name)
  end

  def bos_inst_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :bos_inst, resource_name)
  end

  def maint_boot_aix_nimclient(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_nimclient, :maint_boot, resource_name)
  end

  # Matchers for aix_no.
  def update_aix_no(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_no, :update, resource_name)
  end

  def reset_aix_no(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_no, :reset, resource_name)
  end

  def reset_all_aix_no(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_no, :reset_all, resource_name)
  end

  def reset_all_with_reboot_aix_no(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_no, :reset_all_with_reboot, resource_name)
  end

  # Matchers for aix_niminit.
  def setup_aix_niminit(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_niminit, :setup, resource_name)
  end

  def remove_aix_niminit(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_niminit, :remove, resource_name)
  end

  # Matchers for aix_pagingspace.
  def change_aix_pagingspace(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_pagingspace, :change, resource_name)
  end

  def remove_aix_pagingspace(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_pagingspace, :remove, resource_name)
  end

  def create_aix_pagingspace(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_pagingspace, :create, resource_name)
  end

  # Matchers for aix_subsystem.
  def create_aix_subsystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_subsystem, :create, resource_name)
  end

  def delete_aix_subsystem(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_subsystem, :delete, resource_name)
  end

  # Matchers for aix_subserver.
  def enable_aix_subserver(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_subserver, :enable, resource_name)
  end

  def disable_aix_subserver(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_subserver, :disable, resource_name)
  end

  # Matchers for aix_tcpservice.
  def enable_aix_tcpservice(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_tcpservice, :enable, resource_name)
  end

  def disable_aix_tcpservice(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_tcpservice, :disable, resource_name)
  end

  # Matchers for aix_toolboxpackage.
  def install_aix_toolboxpackage(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_toolboxpackage, :install, resource_name)
  end

  def remove_aix_toolboxpackage(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_toolboxpackage, :remove, resource_name)
  end

  # Matchers for aix_tunables.
  def update_aix_tunables(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_tunables, :update, resource_name)
  end

  def reset_aix_tunables(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_tunables, :reset, resource_name)
  end

  def reset_all_aix_tunables(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_tunables, :reset_all, resource_name)
  end

  # Matchers for aix_volume_group.
  def create_aix_volume_group(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_volume_group, :create, resource_name)
  end

  # Matchers for aix_wpar.
  def create_aix_wpar(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_wpar, :create, resource_name)
  end

  def start_aix_wpar(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_wpar, :start, resource_name)
  end

  def stop_aix_wpar(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_wpar, :stop, resource_name)
  end

  def sync_aix_wpar(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_wpar, :sync, resource_name)
  end

  def delete_aix_wpar(resource_name)
    ChefSpec::Matchers::ResourceMatcher.new(:aix_wpar, :delete, resource_name)
  end
end
