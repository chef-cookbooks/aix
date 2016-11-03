# recipe example flrtvc script on nim clients

aix_flrtvc 'patch quimby12' do
  targets 'quimby02,quimby03,quimby04,quimby05,quimby06,quimby07,quimby08,quimby09'
  verbose true
  clean true
  action [:install, :patch]
end
