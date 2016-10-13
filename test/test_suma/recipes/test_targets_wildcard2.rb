# Expected values
# return code : 0
# suma log info : INFO: List of targets expanded to ["castle", "cattle"]
# suma directory : /sumatest/targets/wildcard2/7100-01-01-1316-lpp_source

node.default['nim'] = { 'clients' => { 'castle' => { 'oslevel' => '7100-02-01-1316' },
                                       'cattle' => { 'oslevel' => '7100-03-01-1316' },
                                       'crow' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Valid client list with wildcard (0500-035)' do
  oslevel   '7100-01-01-1316'
  location  '/sumatest/targets/wildcard2'
  targets   'ca*le'
  action    :download
end
