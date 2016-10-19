# Expected values
# return code : 1
# exception : AIX::PatchMgmt::InvalidLppSourceProperty
#
node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-09-00-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'error lpp source unknown' do
  lpp_source '7100-09-02-0000-lpp_source'
  targets 'client1'
  action :update
end
