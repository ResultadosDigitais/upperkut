require 'securerandom'

module Upperkut
  class Item
    attr_reader :id, :body, :enqueued_at

    def initialize(body:, id: nil, enqueued_at: nil)
      @body = body
      @id = id || SecureRandom.uuid
      @enqueued_at = enqueued_at || Time.now.utc.to_i
      @nacked = false
    end

    def nack
      @nacked = true
    end

    def nacked?
      @nacked
    end
  end
end
