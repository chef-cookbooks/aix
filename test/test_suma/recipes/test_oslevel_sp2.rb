node.default['nim']['clients'] = {'client1' => {'oslevel' => '7100-02-01' }}

aix_suma '12. Downloading SP 7100-02-03-1316' do
  oslevel   '7100-02-03-1316'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
