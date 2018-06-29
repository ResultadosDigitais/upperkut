require_relative '../lib/upperkut/worker'

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
    config.middlewares do |chain|
      chain.add MyMiddleware
    end
  end

  def perform(items)
    puts "executing........."
    exec_time = rand(80..200)
    sleep (exec_time.to_f / 1000.to_f)
  end
end
