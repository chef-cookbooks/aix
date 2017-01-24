# Expected values
# return code : 1
# exception : NimDefineError
# suma directory : /sumatest/suma/error4/7100-02-02-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ERROR ###

node.default['nim']['master'] = { 'oslevel' => '7100-02-01' }
node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Error nim define (Preview + Download + Define ERROR)' do
  oslevel   '7100-02-02-1316'
  location  '/sumatest/suma/error4'
  targets   'client1'
  action    :download
end
