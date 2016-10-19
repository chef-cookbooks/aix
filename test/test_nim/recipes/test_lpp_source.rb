# Expected values
# return code : 0
# exception : nil
# nim cust : ### NIM FAKE DONE CUSTOM OPERATION on client client1 with resource 7100-09-04-0000-lpp_source ###
#
node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-09-00-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'lpp source exists' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client1'
  action :update
end
