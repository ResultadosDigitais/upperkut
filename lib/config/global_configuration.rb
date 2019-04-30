module Upperkut
  class GlobalConfiguration
    attr_accessor :global_server_middlewares, :global_client_middlewares
    
    def initialize
      @global_server_middlewares = []
      @global_client_middlewares = []
    end
  end
end