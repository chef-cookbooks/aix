# Expected values (up-to-date)
# return code : 0
# exception : nil
# nim cust : ""
#
node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-09-04-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'asynchronous update same level' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client1'
  async true
  action :update
end