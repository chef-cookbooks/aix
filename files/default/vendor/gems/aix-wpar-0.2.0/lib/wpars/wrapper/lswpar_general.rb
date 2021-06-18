require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/general'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparGeneral < Lswpar
      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}G #{options[:name]}"
      end

      private

      def parse(output) #:nodoc:
        generals = []

        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |gen|
          general = General.new(gen)
          generals << general
        end
        generals
      end
    end
  end
end
