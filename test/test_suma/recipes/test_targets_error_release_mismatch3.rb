# Expected values
# return code : 1
# exception : AIX::PatchMgmt::InvalidTargetsProperty

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7200-03-01-1316' }, # 7.2 AIX Release
                                       'client3' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Release mismatch oslevel latest (ERROR)' do
  oslevel 'latest'
  location '/sumatest/targets/error7'
  targets 'client1,client2,client3'
  action :download
end
