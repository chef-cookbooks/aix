
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-02-01'}}

aix_suma "41. error no more space 0500-004 (Download ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "42. error network 0500-013 (Preview ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "43. error entitlement 0500-059 (Preview ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "44. error timeout chef (Download ERROR)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "45. error no fixes 0500-035 (Preview only)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "46. nothing to download (Preview only)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "47. failed fixes (Preview + Download)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "48. lpp source exists (Preview + Download)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "49. lpp source absent (Preview + Download + Define)" do
  oslevel   '7100-02-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
