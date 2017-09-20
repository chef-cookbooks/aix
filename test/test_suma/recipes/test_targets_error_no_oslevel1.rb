# Expected values
# return code : 1
# exception : AIX::PatchMgmt::InvalidTargetsProperty

node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '' },
                                       'client2' => { 'oslevel' => '' },
                                       'client3' => { 'oslevel' => '' } },
                        'lpp_sources' => {} }

aix_suma 'No oslevel (ERROR)' do
  oslevel '7100-01-01-1316'
  location '/sumatest/targets/error4'
  targets 'client1,client2,client3'
  action :download
end
