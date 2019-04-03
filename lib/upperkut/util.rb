require 'json'

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

    def encode_json_items(items)
      items = items.collect do |i|
        JSON.generate(
          'enqueued_at' => Time.now.to_i,
          'body' => i
        )
      end
    end

    def decode_json_items(items)
      items.collect! do |i|
        JSON.parse(i) if i
      end

      items.compact!
      items
    end
  end
end
