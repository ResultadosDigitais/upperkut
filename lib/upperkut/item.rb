require 'securerandom'

module Upperkut
  class Item
    attr_reader :id, :body, :enqueued_at

    def initialize(body:, id: nil, enqueued_at: nil)
      raise ArgumentError, 'Body should be a Hash' unless body.is_a?(Hash)

      @id = id || SecureRandom.uuid
      @body = body.transform_keys(&:to_s)
      @enqueued_at = enqueued_at || Time.now.utc.to_i
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

    def to_json
      JSON.generate(
        'id' => @id,
        'body' => @body,
        'enqueued_at' => @enqueued_at
      )
    end

    def self.from_json(item_json)
      hash = JSON.parse(item_json, symbolize_names: true)
      new(hash.slice(:id, :body, :enqueued_at))
    end
  end
end
