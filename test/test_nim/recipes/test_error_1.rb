
node.default['nim']['clients'] = {}
node.default['nim']['lpp_sources']['7100-09-04-lpp_source'] = { 'Rstate' => 'ready for use', 'location' => '/tmp/img.source/7100-09-04-lpp_source/installp/ppc', 'alloc_count' => '0', 'server' => 'master' }

aix_nim 'Updating client unknown' do
  lpp_source '7100-09-04-lpp_source'
  targets   'client1'
  action    :update
end
