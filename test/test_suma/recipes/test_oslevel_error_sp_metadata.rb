# Expected values
# return code : 1
# exception : SumaMetaDataError
# suma directory :
# suma metadata : FAKE SUMA Metadata Error 1
# suma preview :
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Specific SP unknown (ERROR metadata 0500-035)' do
  oslevel   '7100-02-02'
  location  '/sumatest/oslevel/sp3'
  targets   'client1'
  action    :download
end
