# frozen_string_literal: true

require_relative 'buckaruby/action'
require_relative 'buckaruby/amount'
require_relative 'buckaruby/currency'
require_relative 'buckaruby/language'
require_relative 'buckaruby/operation'
require_relative 'buckaruby/payment_method'
require_relative 'buckaruby/transaction_status'
require_relative 'buckaruby/transaction_type'

require_relative 'buckaruby/configuration'
require_relative 'buckaruby/exception'
require_relative 'buckaruby/field_mapper'
require_relative 'buckaruby/gateway'
require_relative 'buckaruby/request'
require_relative 'buckaruby/response'
require_relative 'buckaruby/signature'

require_relative 'buckaruby/version'

require 'logger'

# :nodoc:
module Buckaruby
  # Holds the global Buckaruby configuration.
  class Config
    attr_accessor :logger, :open_timeout, :read_timeout

    def initialize
      @logger = defined?(Rails) ? Rails.logger : Logger.new($stdout)
      @open_timeout = 30
      @read_timeout = 30
    end
  end

  @config = Config.new

  class << self
    attr_reader :config

    def configure
      yield(@config)
    end

    def reset!
      @config = Config.new
    end
  end
end
