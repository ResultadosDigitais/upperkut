require_relative '../lib/upperkut/worker'

class MyWorker
  include Upperkut::Worker

  def perform(items)
    puts 'starting performing'
    loop do
      puts 'hit ctrl+c to exit gracefully ...'
      sleep 3
      if Upperkut::CLI.shutting_down?
        puts 'upperkut is going to shutdown, terminating ...'
        # return Upperkut::Shutdown exception to upperkut enqueue the job
        raise Upperkut::Shutdown
      end
    end
  end
end
