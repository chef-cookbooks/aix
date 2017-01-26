# Expected values
# return code : 1
# exception : AIX::PatchMgmt::InvalidLppSourceProperty
#
node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-09-00-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'error lpp source empty' do
  lpp_source ''
  targets 'client1'
  action :update
end
