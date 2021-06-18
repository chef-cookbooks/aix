require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class RmWpar
      def self.destroy(options = {})
        cmd = if options[:force].nil?
                "#{options[:command]} #{Constants::RMWPAR} #{options[:name]}"
              else
                "#{options[:command]} #{Constants::RMWPAR} -F #{options[:name]}"
              end

        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end
    end
  end
end
