# Expected values
# return code : 1
# exception : AIX::PatchMgmt::NimCustError
# nim cust : " NIM FAKE CUSTOM ERROR "
#
node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-07-02-0000' } },
                        'lpp_sources' => { '7100-08-00-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-08-00-0000-lpp_source' } } }

# lpp_source 7100-08-00-0000-lpp_source is bound to generate an error in fake nim
aix_nim 'error asynchronous update' do
  lpp_source '7100-08-00-0000-lpp_source'
  targets 'client1'
  async true
  action :update
end
