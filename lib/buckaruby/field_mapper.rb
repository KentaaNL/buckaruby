# frozen_string_literal: true

require_relative 'support/case_insensitive_hash'

module Buckaruby
  # Map NVP fields to hashes and multiple values (with index) to arrays.
  module FieldMapper
    module_function

    def map_fields(params, prefix)
      results = []
      index = 1

      loop do
        index_key = "#{prefix}_#{index}_" # brq_services_1_
        index_length = index_key.split(/_[0-9]*_/).length # 1

        # Get all fields starting with prefix and index.
        fields = params.select { |key| key.to_s.start_with?(index_key) }

        break if fields.empty?

        result = Support::CaseInsensitiveHash.new

        fields.each do |key, value|
          splitted_key = key.to_s.split(/_[0-9]*_/) # ["brq_services", "name"]
          key_length = splitted_key.length # 2
          new_key = splitted_key[index_length] # name

          if key_length == index_length + 1
            # Add normal fields to the result.
            result[new_key] = value
          else
            # Recursively map indexed fields.
            result[new_key] ||= begin
              new_prefix = [index_key, new_key].join
              map_fields(fields, new_prefix)
            end
          end
        end

        break if result.empty?

        results << result

        index += 1
      end

      results
    end
  end
end
