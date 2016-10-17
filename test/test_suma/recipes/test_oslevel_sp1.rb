# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/sp1/7100-02-03-1316-lpp_source
# suma metadata : { 'client1' => { 'oslevel' => '7100-02-01' } }
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading SP 7100-02-03-1316' do
  oslevel   '7100-02-03-1316'
  location  '/sumatest/oslevel/sp1'
  targets   'client1'
  action    :download
end
