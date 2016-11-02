# recipe example flrtvc script on nim clients

aix_flrtvc 'patch quimby12' do
  targets 'quimby12'
#  csv '/apar.csv'
#  filesets 'tcp'
#  apar 'sec'
#  verbose true
  action [:install, :patch]
end
