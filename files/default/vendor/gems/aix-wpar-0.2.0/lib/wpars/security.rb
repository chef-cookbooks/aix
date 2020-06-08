module WPAR
  class Security
    attr_reader :name, :state, :privs

    def initialize(params)
      @command = params[:command]
      @name = params[:name]
      @state = params[:state]
      @privs = params[:privs]
    end
  end
end
