# Expected values
# return code : 1
# exception : SumaPreviewError
# suma directory : /sumatest/suma/error1/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview Error 1
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Error network 0500-013 (Preview ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error1'
  targets   'client1'
  action    :download
end
