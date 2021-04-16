# frozen_string_literal: true

require 'logger'

module Buckaruby
  # Configuration settings for the Buckaruby Gateway.
  class Configuration
    TEST_URL = "https://testcheckout.buckaroo.nl/nvp/"
    PRODUCTION_URL = "https://checkout.buckaroo.nl/nvp/"

    def initialize(options)
      @options = options
    end

    def test?
      mode == :test
    end

    def production?
      mode == :production
    end

    def api_url
      test? ? TEST_URL : PRODUCTION_URL
    end

    def website
      @website ||= begin
        website = @options[:website]
        raise ArgumentError, "Missing required parameter: website" if website.to_s.empty?

        website
      end
    end

    def secret
      @secret ||= begin
        secret = @options[:secret]
        raise ArgumentError, "Missing required parameter: secret" if secret.to_s.empty?

        secret
      end
    end

    # Use Buckaroo mode from options, class setting or the default (test).
    def mode
      @mode ||= begin
        mode   = @options.key?(:mode) ? @options[:mode] : Gateway.mode
        mode ||= :test

        if mode != :test && mode != :production
          raise ArgumentError, "Invalid Buckaroo mode provided: #{mode} (expected :test or :production)"
        end

        mode
      end
    end

    # Use the hash method from options or default (SHA-1).
    def hash_method
      @hash_method ||= begin
        hash_method = (@options[:hash_method] || "SHA1").downcase.to_sym

        unless [:sha1, :sha256, :sha512].include?(hash_method)
          raise ArgumentError, "Invalid hash method provided: #{hash_method} (expected :sha1, :sha256 or :sha512)"
        end

        hash_method
      end
    end

    # Use the logger from options, to Rails or to stdout.
    def logger
      @logger ||= begin
        logger   = @options[:logger]
        logger ||= Rails.logger if defined?(Rails)
        logger ||= Logger.new($stdout)
        logger
      end
    end
  end
end
