# recipe example update with altdisk
# if lppchk -vm return code is different
# than zero recipe will fail
# no guard needed here
execute "lppchk" do
  command 'lppchk -vm3'
end

# removing any efixes
aix_fixes "remvoving_efixes" do
  fixes ["all"]
  action :remove
end

# committing filesets
# no guard needed here
execute 'commit' do
  command 'installp -c all'
end

# creating dir for mount
directory "/var/tmp/mnt" do
  action :create
end

# mounting /mnt
mount "/var/tmp/mnt" do
  device '#{node[:nim_server]}:/export/nim/lpp_source'
  fstype 'nfs'
  action :mount
end

# cleaning exsiting altdisk
aix_altdisk "cleanup alternate rootvg" do
  action :cleanup
end

# creating an alternate disk using the
# first disk bigger than the actual rootvg
aix_altdisk "altdisk_by_auto" do
  type :auto
  value "bigger"
  change_bootlist true
  action :create
end

# altdisk needs to be wakeup
# to run a custom operation
aix_altdisk "altdisk_wake_up" do
  action :wakeup
end

# updating the current disk
aix_altdisk "altdisk_update" do
  image_location "/var/tmp/mnt/7100-03-05-1524"
  action :customize
end

# put it to sleep
aix_altdisk "altdisk_sleep" do
  action :sleep
end

# unmount /mnt
mount "/var/tmp/mnt" do
  action :umount
end

# deleting temp directory
directory "/var/tmp/mnt" do
  action :delete
end
