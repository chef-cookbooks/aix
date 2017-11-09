# Expected values
# return code : 0
# suma directory : /sumatest/targets/error6/7200-01-01-1316-lpp_source
# suma preview : ### SUMA FAKE Preview ###

node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7200-03-01-1316' }, # 7.2 AIX Release
                                       'client3' => { 'oslevel' => '7100-04-01-1316' },
                                       'client4' => { 'oslevel' => '7200-02-02-1316' } }, # 7.2 AIX Release
                        'lpp_sources' => {} }

aix_suma 'Release mismatch oslevel 7200-xx-xx (only update 7.2 AIX releases)' do
  oslevel '7200-01-01-1316'
  location '/sumatest/targets/error6'
  targets '*'
  action :download
end
