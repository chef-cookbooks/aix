require 'csv'

module WPAR
  module Wrapper
    module Converter
      def self.convert(output)
        csv = CSV.new(output,
                      :col_sep => ':',
                      :headers => true,
                      :header_converters => :symbol,
                       :converters => :all)
        csv.to_a.map {|row| row.to_hash }
      end
    end
  end
end
