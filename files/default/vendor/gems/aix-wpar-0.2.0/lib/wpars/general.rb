module WPAR
  class General
    attr_reader :name, :state, :type, :rootvgwpar, :routing, :uuid
    attr_reader :vipwpar, :directory, :owner, :script, :privateusr
    attr_reader :checkpointable, :application, :ostype, :xwparipc, :architecture
    attr_accessor :hostname, :auto

    def initialize(params)
      @command = params[:command]
      @name = params[:name]
      @state = params[:state]
      @type = params[:type]
      @rootvgwpar = params[:rootvgwpar]
      @hostname = params[:hostname]
      @routing = params[:routing]
      @vipwpar = params[:vipwpar]
      @directory = params[:directory]
      @owner = params[:owner]
      @script = params[:script]
      @auto = params[:auto] || "no"
      @privateusr = params[:privateusr]
      @checkpointable = params[:checkpointable]
      @application = params[:application]
      @ostype = params[:ostype]
      @xwparipc = params[:xwparipc]
      @architecture = params[:architecture]
      @uuid = params[:uuid]
    end

  end
end
