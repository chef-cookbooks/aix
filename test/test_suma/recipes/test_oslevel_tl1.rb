# Expected values
# return code : 0
# exception : nil
# suma directory : /sumatest/oslevel/tl1/7100-03-00-0000-lpp_source
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define : ### NIM FAKE Define ###

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Downloading TL 7100-03' do
  oslevel   '7100-03'
  location  '/sumatest/oslevel/tl1'
  targets   'client1'
  action    :download
end
