node.default['nim']['clients'] = {'client1'=>{'mllevel'=>'7100-09'},'client2'=>{'mllevel'=>'7100-10'},'client3'=>{'mllevel'=>'7100-08'}}
node.default['nim']['lpp_sources']["7100-09-04-lpp_source"]={"Rstate"=>"ready for use", "location"=>"/tmp/img.source/7100-09-04-lpp_source/installp/ppc", "alloc_count"=>"0", "server"=>"master"}

aix_nim "Updating 2 clients => SP 7100-09-04" do
  lpp_source  "7100-09-04-lpp_source"
  targets     "client1,client2"
  action      :update
end

aix_nim "no updating (lpp not exist) => TL 7100-11" do
  lpp_source  "7100-11-lpp_source"
  targets     "client1,client2"
  action      :update
end
