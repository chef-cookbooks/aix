require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/resource_control'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparResourceControl < Lswpar

      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}R #{options[:name]}"
      end

      private
      def parse(output) #:nodoc:
        resources = []
        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |rsc|
          resource = ResourceControl.new(rsc)
          resources << resource
        end
        return resources
      end
    end
  end
end
