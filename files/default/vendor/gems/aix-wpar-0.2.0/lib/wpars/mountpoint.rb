module WPAR
  class Mountpoint
    attr_reader :name, :mountpoint, :device, :vfs, :nodename, :options

    def initialize(params)
      @command = params[:command]
      @name = params[:name]
      @mountpoint = params[:mountpoint]
      @device = params[:device]
      @vfs = params[:vfs]
      @nodename = params[:nodename]
      @options = params[:options]
    end
  end
end
