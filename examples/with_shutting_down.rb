require_relative '../lib/upperkut/worker'

# Upperkut::CLI.shutting_down? example
class MyWorker
  include Upperkut::Worker

  def perform(items)
    puts "starting performing on #{items}"
    long_waiting
  end

  private

  def long_waiting
    loop do
      puts 'hit ctrl+c to exit gracefully ...'
      sleep 3

      next unless Upperkut::CLI.shutting_down?

      # return Upperkut::Shutdown exception to the upperkut enqueue the job
      puts 'upperkut is going to shutdown, terminating ...'
      raise Upperkut::Shutdown
    end
  end
end
