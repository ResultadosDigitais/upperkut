require 'connection_pool'
require 'redis'

module Upperkut
  class RedisPool
    DEFAULT_OPTIONS = {
      pool_timeout: 1, # pool related option
      size: 2, # pool related option
      connect_timeout: 0.2,
      read_timeout: 5.0,
      write_timeout: 0.5
    }.freeze

    def initialize(options)
      @options      = DEFAULT_OPTIONS.merge(url: ENV['REDIS_URL'])
                                     .merge(options)

      # Extract pool related options
      @size         = @options.delete(:size)
      @pool_timeout = @options.delete(:pool_timeout)
    end

    def create
      ConnectionPool.new(timeout: @pool_timeout, size: @size) do
        Redis.new(@options)
      end
    end
  end
end
