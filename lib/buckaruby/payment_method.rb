module Buckaruby
  module PaymentMethod
    IDEAL = "ideal" # iDEAL collecting
    IDEAL_PROCESSING = "idealprocessing" # iDEAL processing

    SEPA_DIRECT_DEBIT = "sepadirectdebit"
    PAYPAL = "paypal"
    BANCONTACT_MISTER_CASH = "bancontactmrcash"
    TRANSFER = "transfer"

    # Credit cards
    VISA = "visa"
    MASTER_CARD = "mastercard"
    MAESTRO = "maestro"
  end
end
