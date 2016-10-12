# Expected values
# return code : 0
# exception : nil
# suma directory : /usr/sys/inst.images/7100-02-02-1316
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01' } } }

aix_suma 'Empty property location (/usr/sys/inst.images)' do
  oslevel   '7100-02-03'
  location  ''
  targets   'client1'
  action    :download
end
