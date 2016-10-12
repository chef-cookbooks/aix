# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/latest4/7100-02-08-1316
# suma metadata : 
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Empty property oslevel (latest)' do
  oslevel   ''
  location  '/sumatest/oslevel/latest4'
  targets   'client1'
  action    :download
end
