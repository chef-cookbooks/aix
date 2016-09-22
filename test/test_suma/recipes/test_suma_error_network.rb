node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "42. error network 0500-013 (Preview ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/42/'
  targets   'client1'
  action    :download
end
