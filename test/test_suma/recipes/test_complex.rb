
node.default['nim']['clients'] = {'client1'=>{'oslevel'=>'7100-09-00'}}

# Suma run 'up-to-date'
aix_suma "Want to download but up-to-date" do
  name      '7100-09-02'
  location  '/tmp/img.source'
  targets   'client1'
  action    :download
end
