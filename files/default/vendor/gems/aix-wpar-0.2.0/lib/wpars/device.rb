module WPAR
  class Device
    attr_reader :name, :devname, :devtype, :vdevname, :devstatus
    attr_reader :devid, :rootvg, :adapter

    def initialize(params)
      @command = params[:command]
      @name = params[:name]
      @devname = params[:devname]
      @devtype = params[:devtype]
      @vdevname = params[:vdevname]
      @devstatus = params[:devstatus]
      @devid = params[:devid]
      @rootvg = params[:rootvg]
      @adapter = params[:adapter]
    end
  end
end
