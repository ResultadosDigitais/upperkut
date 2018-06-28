require 'logger'
require 'time'
require 'socket'

module Upperkut
  module Logging

    class DefaultFormatter < Logger::Formatter
      def call(severity, time, program_name, message)
        "upperkut: #{time.utc.iso8601(3)} hostname=#{Socket.gethostname} "\
        "pid=#{::Process.pid} severity=#{severity} #{format_message(message)}\n"
      end

      private

      def format_message(message)
        return "msg=#{message} " unless message.is_a?(Hash)

        message.each_with_object('') do |(k,v), memo|
          memo << "#{k}=#{v}\s"
          memo
        end

      end
    end

    def self.initialize_logger
      logger = Logger.new($stdout)
      logger.level     = Logger::INFO
      logger.formatter = DefaultFormatter.new
      logger
    end

    def self.logger
      @logger ||= initialize_logger
    end
  end
end
