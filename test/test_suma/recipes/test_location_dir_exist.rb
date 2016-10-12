# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/location/dir1/7100-02-02-1316
# suma metadata : 
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01' } } }

aix_suma 'No existing directory (absolute path)' do
  oslevel	'7100-02-02-1316'
  location  '/sumatest/location/dir1'
  targets   'client1'
  action    :download
end
