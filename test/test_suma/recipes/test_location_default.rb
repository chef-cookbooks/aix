node.default['nim'] = {'clients' => {'client1' => {'oslevel' => '7100-02-01' }} , 
  'lpp_sources' => {'my_beautiful_lpp-source' => {'location' => '/usr/sys/inst.images/beautiful' } , '7100-02-03-lpp_source' => {'location' => '/usr/sys/inst.images/7100-02-03-lpp_source' }}}

aix_suma '23. Default property location (/usr/sys/inst.images)' do
  oslevel	'7100-02-02'
  #location  '/usr/sys/inst.images'
  targets   'client1'
  action    :download
end
