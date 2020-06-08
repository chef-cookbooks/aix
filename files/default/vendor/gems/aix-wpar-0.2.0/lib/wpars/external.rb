require 'rubygems'
require 'mixlib/shellout'

module WPAR
  module External
    class ExternalFailure < RuntimeError; end

    def cmd(cmd: nil, live_stream: nil)
      command = Mixlib::ShellOut.new(cmd)
      command.live_stream=live_stream if live_stream
      command.run_command
      command.error!
      return command.stdout
    end
    module_function :cmd
  end # module External
end # module WPAR
