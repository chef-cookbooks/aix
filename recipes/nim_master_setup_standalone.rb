# Assume that the aix.sysmgt lpp is available on the system.

# setup nim master
aix_nim 'Install and configure nim master' do
  device '/home/lpp_dir'
  action :master_setup
end
