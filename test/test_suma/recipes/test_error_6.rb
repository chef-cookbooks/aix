
# Suma error 7 
aix_suma "Suma with target empty" do
  oslevel   '7100-10-00'
  location  '/tmp/img.source'
  targets   ''
  action    :download
end
