require_relative '../lib/upperkut/worker'

class MyWorker
  include Upperkut::Worker

  def perform(items)
    puts 'starting performing'
    exec_time = rand(9000..50_000)
    sleep (exec_time.to_f / 1000.to_f)
    puts "performed #{items.size} items in #{exec_time.to_f / 1000.to_f} ms"
  end
end
