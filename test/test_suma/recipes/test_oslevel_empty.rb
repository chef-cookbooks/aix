node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '18. Empty property oslevel (latest)' do
  oslevel   ''
  location  '/tmp/img.source/latest3'
  targets   'client1'
  action    :download
end
