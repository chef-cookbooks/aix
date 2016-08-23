
# Simple test
aix_suma "Downloading SP 6100-09-02" do
  name      '6100-09-02'
  location  '/tmp/img.source'
  targets   'castor3'
  action    :download
end
