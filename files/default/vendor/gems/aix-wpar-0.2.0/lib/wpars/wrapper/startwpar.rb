require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class StartWpar
      def self.start(options = {})
        cmd = "#{options[:command]} #{Constants::STARTWPAR} #{options[:name]}"

        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end
    end
  end
end
