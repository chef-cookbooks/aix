# Expected values
# return code : 0
# suma log info : INFO: List of targets expanded to ["client11", "client21"]
# suma directory : /sumatest/targets/wildcard1/7100-01-01-1316-lpp_source

node.default['nim'] = { 'clients' => { 'client11' => { 'oslevel' => '7100-02-01-1316' },
                                       'client12' => { 'oslevel' => '7100-03-01-1316' },
                                       'client13' => { 'oslevel' => '7100-04-01-1316' },
                                       'client21' => { 'oslevel' => '7100-02-01-1316' },
                                       'client22' => { 'oslevel' => '7100-03-01-1316' },
                                       'client23' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Valid client list with wildcard (0500-035)' do
  oslevel   '7100-01-01-1316'
  location  '/sumatest/targets/wildcard1'
  targets   '*1'
  action    :download
end
