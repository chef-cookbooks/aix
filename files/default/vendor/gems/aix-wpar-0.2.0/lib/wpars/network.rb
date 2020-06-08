require 'ostruct'

#example of a WPAR network object
# <WPAR::Network name="kitchenwpar", interface="en0", address="10.10.10.100", mask_prefix="255.255.255.0", broadcast="10.10.10.255">
module WPAR
  class Network
    attr_reader :name
    attr_accessor :interface, :address, :mask_prefix, :broadcast

    def initialize(params)
      @name = params[:name]
      @interface = params[:interface]
      @address = params[:address]
      @mask_prefix = params[:mask_prefix]
      @broadcast = params[:broadcast]
    end

    def empty?
      wpar_attributes.all?{|k,v| self.send(k).nil?}
    end

    def wpar_attributes
      attrs = Network.instance_methods(false) - [:name, :command, :state, :empty?, :wpar_attributes ]
      attrs - attrs.grep(/=$/)
    end


  end
end
