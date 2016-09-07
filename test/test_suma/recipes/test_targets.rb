
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'},
								  'client2'=>{'oslevel'=>'7100-03-01'},
								  'client3'=>{'oslevel'=>'7100-04-01'}}

aix_suma "31. Valid client list with wildcard" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client*'
  action    :download
end

aix_suma "32. Mostly valid client list" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1,invalid,client3'
  action    :download
end

aix_suma "33. Invalid client list (ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'invalid*'
  action    :download
end

aix_suma "34. Default property targets (all nim clients)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  #targets	'default'
  action    :download
end

aix_suma "35. Empty property targets (all nim clients)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   ''
  action    :download
end

aix_suma "36. Unknown property targets (ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'xxx'
  action    :download
end
