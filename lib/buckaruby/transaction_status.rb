# frozen_string_literal: true

module Buckaruby
  # Parses the transaction status code from Buckaroo.
  module TransactionStatus
    SUCCESS = 1
    FAILED = 2
    REJECTED = 3
    CANCELLED = 4
    PENDING = 5

    module_function

    # See http://support.buckaroo.nl/index.php/Statuscodes
    def parse(brq_statuscode)
      case brq_statuscode
      when '190'
        TransactionStatus::SUCCESS
      when '490', '491', '492'
        TransactionStatus::FAILED
      when '690'
        TransactionStatus::REJECTED
      when '790', '791', '792', '793'
        TransactionStatus::PENDING
      when '890', '891'
        TransactionStatus::CANCELLED
      end
    end
  end
end
