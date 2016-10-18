# Expected values
# return code : 1
# exception : SumaMetadataError
# suma directory :
# suma metadata : ### SUMA FAKE ERROR Metadata 1 ###
# suma preview :
# suma download :
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Specific SP unknown (ERROR metadata 1 - 0500-035)' do
  oslevel   '7100-02-02'
  location  '/sumatest/oslevel/sp3'
  targets   'client1'
  action    :download
end
