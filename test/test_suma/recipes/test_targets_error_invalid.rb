
node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' },
                                   'client2' => { 'oslevel' => '7100-03-01' },
                                   'client3' => { 'oslevel' => '7100-04-01' } }

aix_suma '33. Invalid client list (ERROR)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/33/'
  targets   'invalid*'
  action    :download
end
