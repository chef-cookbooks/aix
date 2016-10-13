# Expected values
# return code : 1
# exception : SumaPreviewError
# suma directory : /sumatest/suma/error2
# suma metadata :
# suma preview : FAKE SUMA Preview Error 2
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Error entitlement 0500-059 (Preview ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error2'
  targets   'client1'
  action    :download
end
