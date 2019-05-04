require_relative 'upperkut/version'
require_relative 'upperkut/worker'
require_relative 'config/configuration'
require 'redis'

# Public: Upperkut is a batch background processing tool for Ruby.
#
# Examples:
#
# 1) Create a Worker class and the define how to process the batch;
#
#   class MyWorker
#     include Upperkut::Worker
#
#     # This is optional
#
#     setup_upperkut do |config|
#       # Define which redis instance you want to use
#       config.strategy = Upperkut::Strategy.new(
#         self,
#         redis: { url: ENV['ANOTHER_REDIS_URL'] }
#       )
#
#       # Define the amount of items must be accumulated
#       config.batch_size = 2_000 # The default value is 1_000
#
#       # How frequent the Processor should hit redis looking for elegible
#       # batch. The default value is 5 seconds. You can also set the env
#       # UPPERKUT_POLLING_INTERVAL.
#       config.polling_interval = 4
#
#       # How long the Processor should wait in seconds to process batch
#       # even though the amount of items did not reached the batch_size.
#       config.max_wait = 300
#     end
#
#     def perform(batch_items)
#       SidekiqJobA.perform_async(batch_items)
#       SidekiqJobB.perform_async(batch_items)
#
#       process_metrics(batch_items)
#     end
#   end
#
# 2) Start pushings items;
#
#   Myworker.push_items(
#     [{'id' => SecureRandom.uuid, 'name' => 'Robert C Hall',  'action' => 'EMAIL_OPENNED'}]
#   )
#
# 3) Start Upperkut;
#
#   $ bundle exec upperkut -worker MyWorker --concurrency 10
#
# 4) That's it :)
module Upperkut
  
  # Upperkut.configuration do |config| 
  #   config.server_middlewares.push(MyServerMiddleware)
  #   config.server_middlewares.push(MyClientMiddleware)
  # end
  def configuration
    @configuration ||= Upperkut::Configuration.new
    yield(@configuration) if block_given?
  end

  class WorkerConfiguration
    attr_accessor :strategy, :polling_interval

    def self.default
      new.tap do |config|
        config.polling_interval = Integer(ENV['UPPERKUT_POLLING_INTERVAL'] || 5)
      end
    end

    def server_middlewares
      @server_middlewares ||= init_server_middleware_chain
      yield @server_middlewares if block_given?
    end

    def client_middlewares
      @client_middlewares ||= init_client_middleware_chain
      yield @client_middlewares if block_given?
    end

    private

    def init_server_middleware_chain
      chain = Middleware::Chain.new

      # deprecated
      if defined?(NewRelic::Agent)
        require_relative 'upperkut/middlewares/new_relic'
        chain.add(Upperkut::Middlewares::NewRelic)
      end

      # deprecated
      if defined?(Rollbar::VERSION)
        require_relative 'upperkut/middlewares/rollbar'
        chain.add(Upperkut::Middlewares::Rollbar)
      end

      # deprecated
      if defined?(Datadog)
        require_relative 'upperkut/middlewares/datadog'
        chain.add(Upperkut::Middlewares::Datadog)
      end

      configuration.server_middlewares.each do |middleware|
        chain.add(middleware)
      end

      chain
    end

    def init_client_middleware_chain
      chain = Middleware::Chain.new
      puts @configuration.class
      configuration.client_middlewares.each do |middleware|
        chain.add(middleware)
      end

      chain
    end
  end

  # Error class responsible to signal the shutdown process
  class Shutdown < StandardError; end
end
