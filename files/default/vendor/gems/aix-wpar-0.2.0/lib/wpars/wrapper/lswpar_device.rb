require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/device'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparDevice < Lswpar

      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}D #{options[:name]}"
      end

      private
      def parse(output) #:nodoc:
        devices = []
        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |dev|
          device = Device.new(dev)
          devices << device
        end
        return devices
      end
    end
  end
end
