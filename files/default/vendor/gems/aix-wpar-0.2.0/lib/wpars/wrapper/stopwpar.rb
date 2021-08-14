require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class StopWpar
      def self.stop(options = {})
        cmd = if options[:force].nil?
                "#{options[:command]} #{Constants::STOPWPAR} #{options[:name]}"
              else
                "#{options[:command]} #{Constants::STOPWPAR} -F #{options[:name]}"
              end

        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end
    end
  end
end
