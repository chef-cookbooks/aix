node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '14. Downloading TL 7100-04-00' do
  oslevel   '7100-04-00'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
