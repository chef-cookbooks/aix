# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/latest3/7100-02-08-1316-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['master'] = { 'oslevel' => '7100-02-01' }
node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Default property oslevel (latest)' do
  # oslevel 'latest'
  location  '/sumatest/oslevel/latest3'
  targets   'client1'
  action    :download
end
