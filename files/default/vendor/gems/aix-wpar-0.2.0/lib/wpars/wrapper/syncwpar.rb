require 'wpars/wrapper/constants'

module WPAR
  module Wrapper
    include Constants
    class SyncWpar
      def self.sync(options = {})
        if options[:dir].nil?
          cmd = "#{options[:command]} #{Constants::SYNCWPAR} -X #{options[:name]}"
        else
          cmd = "#{options[:command]} #{Constants::SYNCWPAR} -D -d #{options[:dir]}  #{options[:name]}"
        end

        puts "debug: #{cmd}" unless options[:debug].nil?
        External.cmd(cmd: cmd, live_stream: options[:live_stream])
      end
    end
  end
end
