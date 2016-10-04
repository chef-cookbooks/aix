node.default['nim'] = { 'clients' => { 'client_error' => { 'oslevel' => '7100-09-00-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'Rstate' => 'ready for use', 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source/installp/ppc', 'alloc_count' => '0', 'server' => 'master' } } }

aix_nim 'Updating but failure' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client_error'
  action :update
end
