# update the VIOSES

Chef::Recipe.send(:include, AIX::PatchMgmt)

aix_nimviosupdate 'Update the VIOSES' do
  targets '(gdrh9v1,gdrh9v2) (gdrh10v1,gdrh10v2)'
  lpp_source 'VIOS_225_30-lpp_source'
  updateios_flags 'install'
  accept_licenses 'yes'
  preview 'no'
  action_list 'update'
end
