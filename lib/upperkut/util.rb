require 'json'
require 'upperkut/item'

module Upperkut
  module Util
    def to_underscore(object)
      klass_name = object
      klass_name.gsub!(/::/, '_')
      klass_name.gsub!(/([A-Z\d]+)([A-Z][a-z])/, '\1_\2')
      klass_name.gsub!(/([a-z\d])([A-Z])/, '\1_\2')
      klass_name.tr!('-', '_')
      klass_name.downcase!
      klass_name
    end

    # Public:
    #  Normalize hash and hash arrays into a hash of Items.
    #  An Item object contains metadata, for example the timestamp from the moment it was enqueued,
    #   that we need to carry through multiple execution tries.
    #
    #  When the execution fails, we need to schedule the whole batch for retry, and scheduling
    #   an Item will make Upperkut understand that we're not dealing with a new batch,
    #   so metrics like latency will increase.
    def normalize_items(items)
      items = [items] unless items.is_a?(Array)

      items.map do |item|
        next item if item.is_a?(Item)

        Item.new(item)
      end
    end

    def decode_json_items(items)
      items.each_with_object([]) do |item, memo|
        memo << Item.from_json(item) if item
      end
    end

    def retry_block(retries_limit = 3, base_sleep = 2)
      retries = 0

      begin
        yield
      rescue StandardError => err
        if retries < retries_limit
          retries += 1
          sleep_time = base_sleep**retries
          Kernel.sleep(sleep_time)
          retry
        end

        raise err
      end
    end
  end
end
