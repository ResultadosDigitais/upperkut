require 'securerandom'

module Upperkut
  class Item
    attr_reader :id, :body, :enqueued_at

    def initialize(id:, body:, enqueued_at: nil)
      normalized_body = if body.is_a?(Hash)
                body.transform_keys(&:to_s)
              else
                body
              end

      @id = id
      @body = normalized_body
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
