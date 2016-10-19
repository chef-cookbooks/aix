# recipe example setup nim master
=begin
Assume that the 'nim_server' is the hostname of the nim server
Assume that lpp_source has already been allocated by nim server and fs exported.
# nim -o allocate -a lpp_source=7143lpp_res quimby01
# exportfs
=end

# mounting /mnt
mount '/mnt' do
  device "#{nim_server}:/export/nim/lpp_source/7143lpp_res"
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

=begin
Do not forget to deallocate the resource on the old nim server
# nim -o deallocate -a lpp_source=7143lpp_res quimby01
=end
