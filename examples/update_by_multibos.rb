# recipe example update with multibos
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

# creating dir for mount
directory '/var/tmp/mnt' do
  action :create
end

# mounting /mnt
mount '/var/tmp/mnt' do
  device "#{node[:nim_server]}:/export/nim/lpp_source"
  fstype 'nfs'
  action :mount
end

# removing standby multibos
aix_multibos 'removing standby bos' do
  :remove
end

# create multibos and updateit
aix_multibos 'creating bos and updating it' do
  update_device '/var/tmp/mnt/7100-03-05-1524'
  action :create
end

# unmount /mnt
mount '/var/tmp/mnt' do
  action :umount
end

# deleting temp directory
directory '/var/tmp/mnt' do
  action :delete
end
