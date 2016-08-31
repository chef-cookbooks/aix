
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09'}}

aix_suma "Want to download but up-to-date" do
  oslevel   '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "Downloading TL 7100-09 >> 7100-10" do
  oslevel   '7100-10'
  targets   'client1'
  action    :download
end

aix_suma "Downloading TL 7100-09 >> 7100-11-00" do
  oslevel   '7100-11-00'
  location  '/tmp/img.source'
  targets   'client1,client0'
  action    :download
end

aix_suma "Downloading Latest 7100-09" do
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "Only preview (already download) 7100-09 >> 7100-09-05" do
  oslevel   '7100-09-05'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end

aix_suma "Downloading SP 7100-09 >> 7100-09-03 with failure" do
  oslevel   '7100-09-03'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
