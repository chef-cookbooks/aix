# Expected values (up-to-date)
# return code : 0
#
node.default['nim'] = { 'master' => { 'oslevel' => '7100-02-01' },
                        'clients' => { 'client1' => { 'oslevel' => '7100-09-04-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'synchronous update same level' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client1'
  async false
  action :update
end
