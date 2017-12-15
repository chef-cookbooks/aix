# recipe example update 
vios = '(gdrh9v1,gdrh9v2) (gdrh10v1,gdrh10v2)'
disks = '(hdisk1,hdisk2) (hdisk1,)'
lpp = 'VIOS_225_30-lpp_source'
update_cmd = 'install'

# check vioses, save rotvg disks and update the vioses
aix_nimviosupdate 'Update the VIOSES' do
  targets vios.to_s
  altdisks disks.to_s
  lpp_source lpp.to_s
  updateios_flags update_cmd.to_s
  accept_licenses 'yes'
  preview 'no'
  action_list 'check, altdisk_copy, update'
end
