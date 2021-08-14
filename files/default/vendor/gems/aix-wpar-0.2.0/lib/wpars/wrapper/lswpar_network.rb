require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/network'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparNetwork < Lswpar
      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}N #{options[:name]}"
      end

      private

      def parse(output) #:nodoc:
        networks = []
        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |net|
          network = Network.new(net)
          networks << network
        end
        networks
      end
    end
  end
end
