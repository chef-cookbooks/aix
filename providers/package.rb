use_inline_resources if defined?(use_inline_resources)

action :install do

  include Opscode::Aixtoolbox::Helper

  package_url = url_for(new_resource.package_name, new_resource.base_url)
  unless package_url.nil?
    remote_file "#{Chef::Config[:cache_dir]}/#{File.basename(new_resource.package_name)}" do
      source package_url
      action :create
    end

    rpm_package new_resource.package_name do
      source "#{Chef::Config[:cache_dir]}/#{File.basename(new_resource.package_name)}"
      action :install
    end
  end
end

action :remove do

  rpm_package new_resource.package_name do
    action :remove
  end

end
