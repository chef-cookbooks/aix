
node.default['nim'] = {'clients'=>{'client1'=>{'oslevel'=>'7100-02-01'}},
'lpp_sources'=>{'7100-02-03-lpp_source'=>{'location'=>'/usr/sys/inst.images'}}}

aix_suma "21. Existing directory (absolute path)" do
  oslevel	'7100-02-02'
  #location  '/'
  targets   'client1'
  action    :download
end

aix_suma "22. Existing directory (relative path)" do
  oslevel	'7100-02-02'
  #location  '.'
  targets   'client1'
  action    :download
end

aix_suma "23. Default property location (/usr/sys/inst.images)" do
  oslevel	'7100-02-02'
  #location  '/usr/sys/inst.images'
  targets   'client1'
  action    :download
end

aix_suma "24. Empty property location (/usr/sys/inst.images)" do
  oslevel   '7100-02-02'
  location  ''
  targets   'client1'
  action    :download
end

aix_suma "25. Unknown property location (create relative directory)" do
  oslevel   '7100-02-02'
  location  'xxx'
  targets   'client1'
  action    :download
end

aix_suma "26. Existing lpp source but different location (ERROR)" do
  oslevel   '7100-02-03'
  location  '/tmp'
  targets   'client1'
  action    :download
end

aix_suma "27. Provide existing lpp source as location" do
  oslevel   '7100-02-02'
  location  '7100-02-02-lpp_source'
  targets   'client1'
  action    :download
end

aix_suma "28. Provide unknown lpp source as location (ERROR)" do
  oslevel   '7100-02-02'
  location  'xxxx-xx-xx-lpp_source'
  targets   'client1'
  action    :download
end
