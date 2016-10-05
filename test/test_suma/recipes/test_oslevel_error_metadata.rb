node.default['nim']['clients'] = { 'client1' => {'oslevel' => '7100-02-01'} }

aix_suma '19b. latest SP for TL unknown (ERROR metadata 0500-035)' do
  oslevel   'latest'
  location  '/tmp/img.source/latest5'
  targets   'client1'
  action    :download
end
