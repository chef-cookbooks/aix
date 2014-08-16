require 'chef/provider'
require 'chef/provider/lwrp_base'

include Opscode::Aixtoolbox::Helpers

class Chef
  class Provider
    class AixtoolboxPackage < Chef::Provider::LWRPBase

      use_inline_resources if defined?(use_inline_resources)

      def whyrun_supported?
        true
      end

      action :install do
        package_url = url_for(new_resource.package_name, new_resource.base_url)
        unless package_url.nil?
          converge_by "install AIX toolbox package #{new_resource.package_name}" do
            remote_file "#{Chef::Config[:file_cache_path]}/#{::File.basename(package_url)}" do
              source package_url
              action :create
            end

            rpm_package new_resource.package_name do
              source "#{Chef::Config[:file_cache_path]}/#{::File.basename(package_url)}"
              action :install
            end
          end
        end
      end

      action :remove do
        converge_by 'remove AIX toolbox package #{new_resource.package_name}' do
          rpm_package new_resource.package_name do
            action :remove
          end
        end
      end

    end
  end
end

Chef::Platform.set :platform => :aix, :resource => :aixtoolbox_package, :provider => Chef::Provider::AixtoolboxPackage
