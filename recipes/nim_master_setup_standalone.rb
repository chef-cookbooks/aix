# Assume that the aix.sysmgt lpp is available on the system.

lpp_dir = '/home/lpp_dir'

# setup nim master
aix_nim 'Install and configure nim master' do
  device lpp_dir.to_s
  action :master_setup
end
