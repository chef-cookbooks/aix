# Expected values
# return code : 0
# exception : nil
# suma directory : /tmp/img.source/latest3
# suma metadata : { 'oslevel' => '7100-02-01' }
# suma preview : FAKE SUMA Preview
# suma download : FAKE SUMA Download
# nim define : FAKE NIM


node.default['nim']['clients'] = { 'client1' => { 'oslevel' => '7100-02-01' } }

aix_suma 'Downloading latest SP for highest TL' do
  oslevel   'laTEst'
  location  '/tmp/img.source/latest1'
  targets   'client1'
  action    :download
end
