require 'wpars/external'
require 'wpars/version'
require 'wpars/wrapper/lswpar_general'
require 'wpars/wrapper/lswpar_network'
require 'wpars/wrapper/lswpar_device'
require 'wpars/wrapper/lswpar_mountpoint'
require 'wpars/wrapper/lswpar_resource_control'
require 'wpars/wrapper/lswpar_security'
require 'wpars/wpar'

module WPAR
  class WPARS
    include Wrapper
    attr_reader :networks, :devices, :mountpoints, :resource_controls
    attr_reader :securities, :generals

    VALID_OPTIONS = [
      :command,
      :version,
      :debug,
    ]

    def initialize(options = {})
      # handy, thanks net-ssh!
      invalid_options = options.keys - VALID_OPTIONS
      if invalid_options.any?
        raise ArgumentError, "invalid option(s): #{invalid_options.join(', ')}"
      end

      # default to loading attributes for the current version
      options[:version] ||= version
      options[:debug] ||= false
      @command = options[:command]
      @generals = LswparGeneral.new(options).list
      @networks = LswparNetwork.new(options).list
      @devices = LswparDevice.new(options).list
      @mountpoints = LswparMountpoint.new(options).list
      @resource_controls = LswparResourceControl.new(options).list
      @securities = LswparSecurity.new(options).list
    end

    def [](name)
      if get_generals(name).nil?
        return
      end
      WPAR.new(name: name,
                      command: @command,
                      general: get_generals(name),
                      networks: get_networks(name),
                      devices: get_devices(name),
                      mountpoints: get_mountpoints(name),
                      resource_controls: get_resource_controls(name),
                      securities: get_securities(name))
    end

    def version
      VERSION
    end

    def get_generals(name)
      begin
        @generals.select { |o| o.name == name }.first
      rescue
        nil
      end
    end

    def get_networks(name)
      @networks.select { |o| o.name == name }
    end

    def get_devices(name)
      @devices.select { |o| o.name == name }
    end

    def get_mountpoints(name)
      @mountpoints.select { |o| o.name == name }
    end

    def get_resource_controls(name)
      begin
        @resource_controls.select { |o| o.name == name }.first
      rescue
        nil
      end
    end

    def get_securities(name)
      begin
        @securities.select { |o| o.name == name }.first
      rescue
        nil
      end
    end
  end
end
