# Expected values
# return code : 0
# nim cust : ### NIM FAKE DONE CUSTOM OPERATION on client client1 with resource 7100-09-04-0000-lpp_source ###
# nim cust : ### NIM FAKE DONE CUSTOM OPERATION on client client2 with resource 7100-09-04-0000-lpp_source ###
#
node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-07-02-0000' },
                                       'client2' => { 'oslevel' => '7100-09-02-0000' },
                                       'client3' => { 'oslevel' => '7100-09-04-0000' },
                                       'client4' => { 'oslevel' => '7100-09-06-0000' },
                                       'client5' => { 'oslevel' => '7100-10-02-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'multi-target synchronous update' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client*'
  async false
  action :update
end
