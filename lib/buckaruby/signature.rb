require 'digest'

module Buckaruby
  # Calculate a signature based on the parameters of the payment request or response.
  # -> see BPE 3.0 Gateway NVP, chapter 4 'Digital Signature'
  class Signature
    def self.generate_signature(params, options)
      secret = options[:secret]
      hash_method = options[:hash_method]

      case hash_method
      when :sha1
        return Digest::SHA1.hexdigest(generate_signature_string(params, secret))
      when :sha256
        return Digest::SHA256.hexdigest(generate_signature_string(params, secret))
      when :sha512
        return Digest::SHA512.hexdigest(generate_signature_string(params, secret))
      else
        raise ArgumentError, "Invalid hash method provided: #{hash_method}"
      end
    end

    def self.generate_signature_string(params, secret)
      sign_params = params.select { |key, _value| key.to_s.upcase.start_with?("BRQ_", "ADD_", "CUST_") && key.to_s.casecmp("BRQ_SIGNATURE").nonzero? }
      string = sign_params.sort_by { |p| p.first.downcase }.map { |param| "#{param[0]}=#{param[1]}" }.join
      string << secret
      return string
    end
  end
end
