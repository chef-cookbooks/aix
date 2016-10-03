node.default['nim'] = {'clients'=>{'client1'=>{'oslevel'=>'7100-02-01'}},
  'lpp_sources'=>{'my_beautiful_lpp-source'=>{'location'=>'/usr/sys/inst.images/7100-02-03-lpp_source'},'7100-02-03-lpp_source'=>{'location'=>'/usr/sys/inst.images/7100-02-03-lpp_source'}}}

aix_suma "26. Existing lpp source but different location (ERROR)" do
  oslevel   '7100-02-03'
  location  '/tmp/img.source/26'
  targets   'client1'
  action    :download
end
