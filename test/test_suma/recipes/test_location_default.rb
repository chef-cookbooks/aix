# Expected values
# return code : 0
# exception : nil
# suma directory : /usr/sys/inst.images/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Default property location (/usr/sys/inst.images)' do
  oslevel   '7100-02-02-1316'
  # location  '/usr/sys/inst.images'
  targets   'client1'
  action    :download
end
