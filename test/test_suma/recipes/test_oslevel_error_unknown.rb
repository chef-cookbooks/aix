node.default['nim']['clients'] = {'client1' => {'oslevel' => '7100-02-01' }}

aix_suma '19. Unknown property oslevel (ERROR)' do
  oslevel   'xxx'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
