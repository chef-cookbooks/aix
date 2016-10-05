node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma '41. error no more space 0500-004 (Download ERROR)' do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/41/'
  targets   'client1'
  action    :download
end
