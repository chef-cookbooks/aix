# Expected values
# return code : 0
# exception : nil
# suma directory : todo
# suma metadata : todo
# suma preview : todo
# suma download : todo
# nim define : todo

node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' },
                                   'client2' => { 'oslevel' => '7100-03-01' },
                                   'client3' => { 'oslevel' => '7100-04-01' } }
node.default['nim']['lpp_sources'] = {}

aix_suma 'Invalid client list (ERROR)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/33/'
  targets   'invalid*'
  action    :download
end
