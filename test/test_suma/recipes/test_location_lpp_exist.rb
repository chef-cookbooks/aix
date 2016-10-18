# Expected values
# return code : 0
# exception : nil
# suma directory : /usr/sys/inst.images/beautiful
# suma metadata :
# suma preview : ### SUMA FAKE Preview ###
# suma download : ### SUMA FAKE Download ###
# nim define :

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01-1316' } }
node.default['nim']['lpp_sources'] = { 'my_beautiful_lpp-source' => { 'location' => '/usr/sys/inst.images/beautiful' } }

aix_suma 'Provide existing lpp source as location' do
  oslevel   '7100-02-02-1316'
  location  'my_beautiful_lpp-source'
  targets   'client1'
  action    :download
end
