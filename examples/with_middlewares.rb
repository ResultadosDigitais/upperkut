require_relative '../lib/upperkut/worker'
require_relative '../lib/upperkut/logging'

class ClientMiddleware
  def call(worker, items)
    logger = Upperkut::Logging.logger

    logger.info("inserting worker=#{worker} items=#{items.count}")
    yield
    logger.info("inserted worker=#{worker} items=#{items.count}")
  end
end

class MyMiddleware
  def call(worker, items)
    logger = Upperkut::Logging.logger

    logger.info("performing worker=#{worker} items=#{items.count}")
    yield
    logger.info("performed worker=#{worker} items=#{items.count}")
  end
end

class WithMiddlewares
  include Upperkut::Worker

  setup_upperkut do |config|
    config.server_middlewares do |chain|
      chain.add MyMiddleware
    end

    config.client_middlewares do |chain|
      chain.add ClientMiddleware
    end
  end

  def perform(_items)
    puts 'executing.........'
    exec_time = rand(80..200)
    sleep (exec_time.to_f / 1000.to_f)
  end
end
