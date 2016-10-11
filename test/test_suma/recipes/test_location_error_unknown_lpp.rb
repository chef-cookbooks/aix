# Expected values
# return code : 0
# exception : nil
# suma directory : […]
# suma metadata : […]
# suma preview : […]
# suma download : […]
# nim define : […]

node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-02-01' } },
                        'lpp_sources' => { 'my_beautiful_lpp-source' => { 'location' => '/usr/sys/inst.images/7100-02-03-lpp_source' }, '7100-02-03-lpp_source' => { 'location' => '/usr/sys/inst.images/7100-02-03-lpp_source' } } }

aix_suma 'Provide unknown lpp source as location (ERROR)' do
  oslevel   '7100-02-02'
  location  'unknown_lpp-source'
  targets   'client1'
  action    :download
end
