# Expected values
# return code : 0
# exception : nil
# suma directory : /usr/sys/inst.images/beautiful
# suma metadata :
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM Define

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }
node.default['nim']['lpp_sources'] = { 'my_beautiful_lpp-source' => { 'location' => '/usr/sys/inst.images/beautiful' } }

aix_suma 'Provide existing lpp source as location' do
  oslevel   '7100-02-02-1316'
  location  'my_beautiful_lpp-source'
  targets   'client1'
  action    :download
end
