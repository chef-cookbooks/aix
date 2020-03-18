module WPAR
  module Wrapper
    class Lswpar

      def list
        data = parse(External.cmd(cmd: @command))

        if block_given?
          return data.each { |obj| yield obj }
        else
          return data
        end
      end

      def filter(name)
        list.select { |o| o.name == name }
      end
    end
  end
end
