# Check the "health" of the given VIOSES
Chef::Recipe.send(:include, AIX::PatchMgmt)

aix_nimviosupdate 'check VIOS healtheness' do
  targets '(gdrh9v1,gdrh9v2) (gdrh10v1,gdrh10v2)'
  action_list 'check'
end
