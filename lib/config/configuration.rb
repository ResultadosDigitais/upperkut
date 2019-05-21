module Upperkut
  # Allows global configuration like below:
  #
  # Upperkut.config do |config|
  #   config.server_middlewares.push(MyServerMiddleware)
  #   config.server_middlewares.push(MyOtherServerMiddleware)
  #
  #   config.client_middlewares.push(MyClientMiddleware)
  #   config.client_middlewares.push(MyOtherClientMiddleware)
  # end
  class Configuration
    attr_accessor :server_middlewares, :client_middlewares

    def initialize
      @server_middlewares = []
      @client_middlewares = []
    end
  end
end
