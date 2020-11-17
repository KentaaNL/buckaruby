# frozen_string_literal: true

require 'digest'

module Buckaruby
  # Calculate a signature based on the parameters of the payment request or response.
  # -> see BPE 3.0 Gateway NVP, chapter 4 'Digital Signature'
  module Signature
    module_function

    def generate_signature(params, config)
      case config.hash_method
      when :sha1
        Digest::SHA1.hexdigest(generate_signature_string(params, config.secret))
      when :sha256
        Digest::SHA256.hexdigest(generate_signature_string(params, config.secret))
      when :sha512
        Digest::SHA512.hexdigest(generate_signature_string(params, config.secret))
      else
        raise ArgumentError, "Invalid hash method provided: #{config.hash_method}"
      end
    end

    def generate_signature_string(params, secret)
      sign_params = params.select { |key, _value| key.to_s.upcase.start_with?("BRQ_", "ADD_", "CUST_") && key.to_s.casecmp("BRQ_SIGNATURE").nonzero? }
      sign_params = order_signature_params(sign_params)

      string = sign_params.map { |param| "#{param[0]}=#{param[1]}" }.join
      string << secret
      string
    end

    # Excerpt from the Buckaroo documentation, chapter 4 'Digital Signature':
    #   In the payment engine, the used lexical sort algorithm uses the following order:
    #   symbols first, then numbers, then case insensitive letters. Also, a shorter string
    #   that is identical to the beginning of a longer string, comes before the longer string.
    #   Take for example the following, comma separated, list which has been sorted:
    #     a_a, a0, a0a, a1a, aaA, aab, aba, aCa
    CHAR_ORDER = "_01234567890abcdefghijklmnopqrstuvwxyz"

    def order_signature_params(params)
      params.sort_by do |key, _value|
        key.to_s.downcase.each_char.map { |c| CHAR_ORDER.index(c) }
      end
    end
  end
end
