# recipe example update with nimclient
# if lppchk -vm return code is different
# than zero recipe will fail
# no guard needed here
execute 'lppchk' do
  command 'lppchk -vm3'
end

# removing any efixes
aix_fixes 'remvoving_efixes' do
  fixes ['all']
  action :remove
end

# committing filesets
# no guard needed here
execute 'commit' do
  command 'installp -c all'
end

# cleaning exsiting altdisk
aix_altdisk 'cleanup alternate rootvg' do
  action :cleanup
end

# creating an alternate disk using the
# first disk bigger than the actual rootvg
# bootlist to false as this disk is just a backup copy
aix_altdisk 'altdisk_by_auto' do
  type :auto
  value 'bigger'
  change_bootlist false
  action :create
end

# nimclient configuration
aix_niminit node['hostname'] do
  master 'nim'
  connect 'nimsh'
  pif_name node['network']['default_interface']
  action :setup
end

# update to latest available tl/sp
aix_nimclient 'updating to latest sp' do
  installp_flags 'aXYg'
  lpp_source 'latest_tl'
  fixes 'update_all'
  action :cust
end

# dealloacate resource
aix_nimclient 'deallocating resources' do
  action :deallocate
end
