module WPAR
  module Name
    def [](name)
      select {|o| o.name == name}
    end
  end
end
