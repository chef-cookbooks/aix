# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/targets/master2/7100-01-01-1316-lpp_source
# suma preview : ### SUMA FAKE Preview ###

node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7100-03-01-1316' },
                                       'client3' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Empty property targets (local master)' do
  oslevel '7100-01-01-1316'
  location '/sumatest/targets/master2'
  targets ''
  action :download
end
