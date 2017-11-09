# Expected values
# return code : 0
# suma log warn : WARN: Release level mismatch, only AIX 7.2 SP/TL will be downloaded
# suma directory : /sumatest/targets/error7/7200-03-08-1316-lpp_source
# suma metadata : ### SUMA FAKE Metadata ###
# suma preview : ### SUMA FAKE Preview ###

node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7200-03-01-1316' }, # 7.2 AIX Release
                                       'client3' => { 'oslevel' => '7100-04-01-1316' },
                                       'client4' => { 'oslevel' => '7200-02-02-1316' } }, # 7.2 AIX Release
                        'lpp_sources' => {} }

aix_suma 'Release mismatch oslevel latest (ERROR)' do
  oslevel 'latest'
  location '/sumatest/targets/error7'
  targets '*'
  action :download
end
