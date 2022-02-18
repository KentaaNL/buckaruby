# frozen_string_literal: true

require 'bigdecimal'

module Buckaruby
  # Helper for converting/formatting amounts.
  class Amount
    def initialize(amount)
      @amount = BigDecimal(amount.to_s)
    end

    def positive?
      @amount.positive?
    end

    def to_d
      @amount
    end

    # Convert the amount to a String with 2 decimals.
    def to_s
      format('%.2f', @amount)
    end
  end
end
