module Upperkut
  class Configuration
    attr_accessor :server_middlewares, :client_middlewares
    
    def initialize
      @server_middlewares = []
      @client_middlewares = []
    end
  end
end