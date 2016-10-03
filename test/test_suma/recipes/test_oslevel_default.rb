node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "17. Default property oslevel (latest)" do
  #oslevel	'latest'
  location  '/tmp/img.source/latest2'
  targets   'client1'
  action    :download
end
