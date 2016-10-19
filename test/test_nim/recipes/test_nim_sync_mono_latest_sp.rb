# Expected values
# return code : 0
# nim cust : ### NIM FAKE DONE CUSTOM OPERATION on client client1 with resource 7100-09-05-0000-lpp_source ###
#
node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-09-00-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' },
                                           '7100-09-05-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-05-0000-lpp_source' },
                                           '7100-10-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-10-04-0000-lpp_source' },
                                           '7100-11-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-11-04-0000-lpp_source' },
                                           '7100-11-06-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-11-06-0000-lpp_source' } }	}

aix_nim 'synchronous update latest sp' do
  lpp_source 'latest_sp'
  targets 'client1'
  async false
  action :update
end
