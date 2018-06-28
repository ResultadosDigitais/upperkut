require 'optparse'
require_relative '../upperkut'
require_relative 'manager'
require_relative 'logging'

module Upperkut
  class CLI
    def initialize(args = ARGV)
      @options = {}
      @logger = Upperkut::Logging.logger

      parse_options(args)
    end

    def start
      if file = @options[:file]
        require file
      end

      if log_level = @options[:log_level]
        @logger.level = log_level
      end

      manager = Manager.new(@options)

      @logger.info(@options)

      r, w = IO.pipe
      signals = %w[INT TERM]

      signals.each do |signal|
        trap signal do
          w.puts(signal)
        end
      end

      begin
        manager.run
        while readable_io = IO.select([r])
          signal = readable_io.first[0].gets.strip
          handle_signal(signal)
        end
      rescue Interrupt
        @logger.info(
          'Stopping managers, wait for 5 seconds and them kill processors'
        )

        manager.stop
        sleep(5)
        manager.kill
        exit(0)
      end
    end

    private

    def handle_signal(sig)
      case sig
      when 'INT'
        raise Interrupt
      when 'TERM'
        raise Interrupt
      end
    end

    def parse_options(args)
      OptionParser.new do |o|
        o.on('-w', '--worker WORKER', 'Define worker to be processed') do |arg|
          @options[:worker] = arg
        end
        o.on('-r', '--require FILE', 'Indicate a file to be required') do |arg|
          @options[:file] = arg
        end
        o.on('-c', '--concurrency INT', 'Numbers of threads to spawn') do |arg|
          @options[:concurrency] = Integer(arg)
        end
        o.on('-l', '--log-level LEVEL', 'Log level') do |arg|
          @options[:log_level] = arg
        end
      end.parse!(args)
    end
  end
end
