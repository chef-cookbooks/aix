require 'wpars/wrapper/constants'
require 'wpars/wrapper/converter'
require 'wpars/wrapper/lswpar'
require 'wpars/mountpoint'

module WPAR
  module Wrapper
    include Constants
    include Converter
    class LswparMountpoint < Lswpar
      def initialize(options)
        @command = "#{options[:command]} #{Constants::LSWPAR}M #{options[:name]}"
      end

      private

      def parse(output) #:nodoc:
        mountpoints = []
        # remove sharp character
        output.slice!(0)

        Converter.convert(output).each do |mnt|
          mountpoint = Mountpoint.new(mnt)
          mountpoints << mountpoint
        end
        mountpoints
      end
    end
  end
end
