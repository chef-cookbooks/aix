# recipe example update 

Chef::Recipe.send(:include, AIX::PatchMgmt)

puts '#########################################################'
puts 'Available VIOS and their corresponding oslevel are:'
puts vios(node)
puts 'Choose one or two VIOS (space separated) to update?'
puts '(The pair of VIOSes must manage the same LPARs)'
vios = STDIN.readline.chomp
vios_list = vios.to_s.strip.split()
tuple = '(' + vios_list[0].to_s
if vios_list.length > 1
  tuple = tuple + ',' + vios_list[1].to_s
end
tuple = tuple + ')'

puts '#########################################################'
puts 'Choose action list (comma separated) to execute on the choosen vioses?'
puts 'check, altdisk_copy, update, altdisk_cleanup'
actions = STDIN.readline.chomp

hdisk_list = []
if actions.include?('altdisk_copy')
  vios_list.each do |vios|
    puts '#########################################################'
    puts ('Choose a disk to build the alternate disk copy on vios: ' + vios)
    puts 'If no disk is chosen, one will be automaticaly selected.'
    puts ('Available free disks for: ' + vios)
    puts free_vios_disks(vios)

    hdisk = STDIN.readline.chomp
    if hdisk.empty?
      hdisk_list.push(" ")
    else
      hdisk_list.push(hdisk)
    end
  end
else
  vios_list.each do |vios|
    hdisk_list.push(" ")
  end
end
disks = '(' + hdisk_list[0].to_s
if hdisk_list.length > 1
  disks = disks + ',' + hdisk_list[1].to_s
end
disks = disks + ')'

lpp = ""
if actions.include?('update')
    puts '#########################################################'
    puts 'Available LPP are:'
    puts list_lpp_sources()
    puts 'Choose one to install?'
    lpp = STDIN.readline.chomp
end

# check vioses, save rotvg disks and update the vioses
aix_nimviosupdate 'Update the VIOSES' do
  targets tuple.to_s
  altdisks disks.to_s
  lpp_source lpp.to_s
  updateios_flags 'install'
  accept_licenses 'yes'
  preview 'no'
#  action_list 'check, altdisk_copy, update'
  action_list actions.to_s
end
