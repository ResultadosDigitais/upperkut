require 'securerandom'

module Upperkut
  class Item
    class InvalidStateTransition < RuntimeError; end

    attr_reader :id, :body, :enqueued_at

    def initialize(body:, id: nil, enqueued_at: nil)
      raise ArgumentError, 'Body should be a Hash' unless body.is_a?(Hash)

      @body = body
      @id = id || SecureRandom.uuid
      @enqueued_at = enqueued_at || Time.now.utc.to_i
      @nacked = false
    end

    def [](key)
      @body[key]
    end

    def []=(key, value)
      @body[key] = value
    end

    def key?(key)
      @body.key?(key)
    end

    def nack
      @nacked = true
    end

    def nacked?
      @nacked
    end

    def to_json
      JSON.generate(
        'id' => @id,
        'body' => @body,
        'enqueued_at' => @enqueued_at
      )
    end

    def self.from_json(item_json)
      hash = JSON.parse(item_json)
      id, body, enqueued_at = hash.values_at('id', 'body', 'enqueued_at')
      new(id: id, body: body, enqueued_at: enqueued_at)
    end
  end
end
