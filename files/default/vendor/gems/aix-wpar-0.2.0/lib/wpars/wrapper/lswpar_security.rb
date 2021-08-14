require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/security'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparSecurity < Lswpar
      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}S #{options[:name]}"
      end

      private

      def parse(output) #:nodoc:
        securities = []
        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |sec|
          security = Security.new(sec)
          securities << security
        end
        securities
      end
    end
  end
end
