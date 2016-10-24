# recipe example setup nim master
# Assume that the 'nim_server' is the hostname of the nim server
# Assume that the level of lpp_source required for installing bos.sysmgmt.nim.master
# has already been allocated by nim server and fs exported.
# > nim -o allocate -a lpp_source=<lpp_source> <new_nim_server>
# > exportfs

nim_server = 'fattony01'
lpp_source = '7143lpp_res'

# mounting /mnt
mount '/mnt' do
  device "#{nim_server}:/export/nim/lpp_source/#{lpp_source}"
  fstype 'nfs'
  action :mount
end

# setup nim master
aix_nim 'Install nim package' do
  device '/mnt'
  action :master_setup
end

# unmount /mnt
mount '/mnt' do
  action :umount
end

# Do not forget to deallocate the resource on the old nim server
# > nim -o deallocate -a lpp_source=<lpp_source> <new_nim_server>
