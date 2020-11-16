# frozen_string_literal: true

module Buckaruby
  module PaymentMethod
    IDEAL = "ideal" # iDEAL collecting
    IDEAL_PROCESSING = "idealprocessing" # iDEAL processing

    SEPA_DIRECT_DEBIT = "sepadirectdebit"
    PAYPAL = "paypal"
    BANCONTACT_MISTER_CASH = "bancontactmrcash"
    SOFORT = "sofortueberweisung"
    TRANSFER = "transfer"

    # Credit cards
    VISA = "visa"
    MASTER_CARD = "mastercard"
    MAESTRO = "maestro"
    AMERICAN_EXPRESS = "amex"
  end
end
