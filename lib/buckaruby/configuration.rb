# frozen_string_literal: true

require 'logger'

module Buckaruby
  # Configuration settings for the Buckaruby Gateway.
  class Configuration
    TEST_URL = "https://testcheckout.buckaroo.nl/nvp/"
    PRODUCTION_URL = "https://checkout.buckaroo.nl/nvp/"

    attr_reader :website, :secret, :mode, :hash_method, :logger

    def initialize(options)
      set_website(options)
      set_secret(options)
      set_buckaroo_mode(options)
      set_hash_method(options)
      set_logger(options)
    end

    def test?
      @mode == :test
    end

    def production?
      @mode == :production
    end

    def api_url
      test? ? TEST_URL : PRODUCTION_URL
    end

    private

    def set_website(options)
      @website = options[:website]

      raise ArgumentError, "Missing required parameter: website" if @website.to_s.empty?
    end

    def set_secret(options)
      @secret = options[:secret]

      raise ArgumentError, "Missing required parameter: secret" if @secret.to_s.empty?
    end

    # Set Buckaroo mode from options, class setting or the default (test).
    def set_buckaroo_mode(options)
      @mode = options.key?(:mode) ? options[:mode] : Gateway.mode
      @mode ||= :test

      if @mode != :test && @mode != :production
        raise ArgumentError, "Invalid Buckaroo mode provided: #{@mode} (expected :test or :production)"
      end
    end

    # Set the hash method from options or default (SHA-1).
    def set_hash_method(options)
      @hash_method = (options[:hash_method] || "SHA1").downcase.to_sym

      unless [:sha1, :sha256, :sha512].include?(@hash_method)
        raise ArgumentError, "Invalid hash method provided: #{@hash_method} (expected :sha1, :sha256 or :sha512)"
      end
    end

    # Set the logger from options, to Rails or to stdout.
    def set_logger(options)
      @logger   = options[:logger]
      @logger ||= Rails.logger if defined?(Rails)
      @logger ||= Logger.new(STDOUT)
    end
  end
end
