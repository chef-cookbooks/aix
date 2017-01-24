# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/sp2/7100-02-02-1316-lpp_source
# suma metadata : ### SUMA FAKE Metadata ###
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['master'] = { 'oslevel' => '7100-02-01' }
node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading SP 7100-02-02' do
  oslevel   '7100-02-02'
  location  '/sumatest/oslevel/sp2'
  targets   'client1'
  action    :download
end
