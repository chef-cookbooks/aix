# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/tl2/7100-03-00-0000-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading TL 7100-03-00' do
  oslevel   '7100-03-00'
  location  '/sumatest/oslevel/tl2'
  targets   'client1'
  action    :download
end
