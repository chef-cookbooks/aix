node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "45. error no fixes 0500-035 (Preview only)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/45/'
  targets   'client1'
  action    :download
end

aix_suma "46. nothing to download (Preview only)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/46/'
  targets   'client1'
  action    :download
end

aix_suma "47. failed fixes (Preview + Download)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/47/'
  targets   'client1'
  action    :download
end

aix_suma "48. lpp source exists (Preview + Download)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/48/'
  targets   'client1'
  action    :download
end

aix_suma "49. lpp source absent (Preview + Download + Define)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source/49/'
  targets   'client1'
  action    :download
end
