# alternate disk copy of the rootvg

Chef::DSL::Recipe.include AIX::PatchMgmt

aix_nimviosupdate 'Copy rootvg disks of VIOSes' do
  targets '(gdrh9v1,gdrh9v2) (gdrh10v1,gdrh10v2)'
  altdisks '(hdisk1,hdisk2) (hdisk1,)'
  action_list 'altdisk_copy'
end
