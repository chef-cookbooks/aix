# Expected values
# return code : 0
# suma log info : INFO: List of targets expanded to ["client1", "client2", "client3"]
# suma directory : /sumatest/targets/wildcard4/7100-01-01-1316-lpp_source

node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7100-03-01-1316' },
                                       'client3' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Valid client list with wildcard (0500-035)' do
  oslevel   '7100-01-01-1316'
  location  '/sumatest/targets/wildcard4'
  targets   '*'
  action    :download
end
