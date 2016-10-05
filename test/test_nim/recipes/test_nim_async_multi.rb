node.default['nim'] = { 'clients' => { 'client1' => { 'oslevel' => '7100-07-02-0000' },
                                       'client2' => { 'oslevel' => '7100-09-02-0000' },
                                       'client3' => { 'oslevel' => '7100-09-04-0000' },
                                       'client4' => { 'oslevel' => '7100-09-06-0000' },
									   'client5' => { 'oslevel' => '7100-10-02-0000' } },
                        'lpp_sources' => { '7100-09-04-0000-lpp_source' => { 'location' => '/tmp/img.source/7100-09-04-0000-lpp_source' } } }

aix_nim 'multi-target asynchronous update' do
  lpp_source '7100-09-04-0000-lpp_source'
  targets 'client*'
  async true
  action :update
end
