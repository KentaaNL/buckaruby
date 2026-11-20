# frozen_string_literal: true

module Buckaruby
  # Supported payment methods.
  module PaymentMethod
    # Bank Payments
    IDEAL = 'ideal' # iDEAL collecting
    IDEAL_PROCESSING = 'idealprocessing' # iDEAL processing
    PAY_BY_BANK = 'paybybank'
    SOFORT = 'sofortueberweisung'
    GIROPAY = 'giropay'
    TRANSFER = 'transfer'

    # Direct Debit
    SEPA_DIRECT_DEBIT = 'sepadirectdebit'

    # Cards
    AMERICAN_EXPRESS = 'amex'
    BANCONTACT = 'bancontactmrcash'
    MAESTRO = 'maestro'
    MASTER_CARD = 'mastercard'
    VISA = 'visa'

    # Wallets
    PAYPAL = 'paypal'

    # Returns an array of all payment method values.
    def all
      constants.map { |c| const_get(c) }
    end

    module_function :all
  end
end
