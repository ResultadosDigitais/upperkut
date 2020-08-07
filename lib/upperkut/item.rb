require 'securerandom'

module Upperkut
  class Item
    attr_reader :id, :body, :enqueued_at

    def initialize(id:, body:, enqueued_at: nil)
      @id = id
      @body = body
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
