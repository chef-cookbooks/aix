require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class StopWpar
      def self.stop(options = {})
        unless options[:force].nil?
          cmd = "#{options[:command]} #{Constants::STOPWPAR} -F #{options[:name]}"
        else
          cmd = "#{options[:command]} #{Constants::STOPWPAR} #{options[:name]}"
        end

        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end
    end
  end
end
