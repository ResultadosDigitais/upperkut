module Upperkut
  class Job
    attr_reader :body, :enqueued_at

    def initialize(body, enqueued_at = nil)
      raise ArgumentError, 'Body should be a Hash' unless body.is_a?(Hash)

      @body = body
      @enqueued_at = enqueued_at || Time.now.utc.to_i
    end

    def [](key)
      @body[key]
    end

    def []=(key, value)
      @body[key] = value
    end

    def to_json
      JSON.generate(
        'body' => @body,
        'enqueued_at' => @enqueued_at,
      )
    end

    def self.from_json(job_json)
      hash = JSON.parse(job_json, symbolize_names: true)
      new(hash)
    end
  end
end

