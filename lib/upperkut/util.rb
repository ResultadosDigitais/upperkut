require 'json'
require 'upperkut/job'

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
      items.collect { |i| i.to_json }
    end

    def decode_json_items(items)
      items.each_with_object([]) do |item, memo|
        memo << Job.from_json(item) if item
      end
    end
  end
end
