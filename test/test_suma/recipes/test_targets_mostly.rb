# Expected values
# return code : 0
# suma log info : INFO: List of targets expanded to ["client1", "client3"]
# suma directory : /sumatest/targets/multi1/7100-01-01-1316-lpp_source

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01-1316' },
                                       'client2' => { 'oslevel' => '7100-03-01-1316' },
                                       'client3' => { 'oslevel' => '7100-04-01-1316' } },
                        'lpp_sources' => {} }

aix_suma 'Mostly valid client list (0500-035)' do
  oslevel '7100-01-01-1316'
  location '/sumatest/targets/multi1'
  targets 'client1,invalid,client3'
  action :download
end
