# recipe example flrtvc script on nim clients

aix_flrtvc 'patch aix machine(s)' do
  verbose true
  clean false
  targets '*'
  apar 'hiper'
  action [:install, :patch]
  check_only true
end
