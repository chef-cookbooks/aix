require 'wpars/external'
require 'wpars/version'
require 'wpars/general'
require 'wpars/network'
require 'wpars/device'
require 'wpars/mountpoint'
require 'wpars/resource_control'
require 'wpars/security'
require 'wpars/wrapper/lswpar_general'
require 'wpars/wrapper/lswpar_network'
require 'wpars/wrapper/lswpar_device'
require 'wpars/wrapper/lswpar_mountpoint'
require 'wpars/wrapper/lswpar_resource_control'
require 'wpars/wrapper/lswpar_security'
require 'wpars/wrapper/mkwpar'
require 'wpars/wrapper/rmwpar'
require 'wpars/wrapper/stopwpar'
require 'wpars/wrapper/startwpar'
require 'wpars/wrapper/syncwpar'

module WPAR
  class WPAR
    include Wrapper

    attr_reader :networks, :devices, :mountpoints, :resource_control
    attr_reader :security, :general, :name
    attr_accessor :live_stream

    def initialize(options = {})
      @command = options[:command]
      @name = options[:name]
      @general = options[:general] || General.new(name: @name)
      @networks = options[:networks] || Array.new([Network.new(name: @name)])
      @devices = options[:devices] || Array.new([Device.new(name: @name)])
      @mountpoints = options[:mountpoints] || Array.new([Mountpoint.new(name: @name)])
      @resource_control = options[:resource_controls] || ResourceControl.new(name: @name)
      @security = options[:securities] || Security.new(name: @name)
    end

    def create(options = {})
      MkWpar.create(name: @name,
                      command: @command,
                      wpar: self,
                      start: options[:start],
                      rootvg: options[:rootvg],
                      wparvg: options[:wparvg],
                      backupimage: options[:backupimage],
                      live_stream: @live_stream)
      # update
      update(options)
    end

    def destroy(force: nil)
      RmWpar.destroy(name: @name, force: force, command: @command, live_stream: @live_stream)
    end

    def stop(force: nil)
      StopWpar.stop(name: @name, force: force, command: @command, live_stream: @live_stream)

      # update status
      @general = LswparGeneral.new(command: @command).filter(@name)
    end

    def start
      StartWpar.start(name: @name, command: @command, live_stream: @live_stream)

      # update status
      @general = LswparGeneral.new(command: @command).filter(@name)
    end

    def sync(directory: nil)
      SyncWpar.sync(name: @name, command: @command, directory: directory, live_stream: @live_stream)
    end

    def update(options = {})
      options[:command] = @command
      @general = LswparGeneral.new(options).filter(@name)
      @networks = LswparNetwork.new(options).filter(@name)
      @devices = LswparDevice.new(options).filter(@name)
      @mountpoints = LswparMountpoint.new(options).filter(@name)
      @resource_control = LswparResourceControl.new(options).filter(@name)
      @security = LswparSecurity.new(options).filter(@name)
    end

    def add(address: nil, interface: nil, mask_prefix: nil, broadcast: nil)
      params = {}
      params[:name] = @name
      params[:address] = address
      params[:interface] = interface
      params[:mask_prefix] = mask_prefix
      params[:broadcast] = broadcast

      net = WPARS::Network.new(params)
      @nets += net
    end

    def get_rootvg
      @devices.select { |o| o.rootvg == 'yes' }
    end
  end
end
