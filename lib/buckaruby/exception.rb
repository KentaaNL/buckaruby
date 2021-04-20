# frozen_string_literal: true

module Buckaruby
  # Base class for exceptions.
  class BuckarooException < StandardError
  end

  # Exception raised when an API call to Buckaroo results in a "Fail".
  class ApiException < BuckarooException
    attr_reader :params

    def initialize(params = {})
      @params = params

      if status_message && status_code
        message = "API request failed: #{status_message} (#{status_code})"
      elsif error_message
        message = "API request failed: #{error_message}"
      else
        message = "API request failed"
      end

      super(message)
    end

    def status_message
      params[:brq_statusmessage]
    end

    def status_code
      params[:brq_statuscode]
    end

    def error_message
      params[:brq_apierrormessage]
    end
  end

  # Exception raised when a request to Buckaroo fails because of connection problems.
  class ConnectionException < BuckarooException
    def initialize(exception)
      message = "Error connecting to Buckaroo: #{exception.message} (#{exception.class})"
      super(message)
    end
  end

  # Exception raised when the response from Buckaroo was invalid.
  class InvalidResponseException < BuckarooException
    attr_reader :response

    def initialize(response)
      @response = response

      message = "Invalid response received from Buckaroo: #{response.message} (#{response.code})"
      super(message)
    end
  end

  # Exception raised when the signature could not be verified.
  class SignatureException < BuckarooException
    attr_reader :sent_signature, :generated_signature

    def initialize(sent_signature, generated_signature)
      @sent_signature = sent_signature
      @generated_signature = generated_signature

      message = "Sent signature (#{sent_signature}) doesn't match generated signature (#{generated_signature})"
      super(message)
    end
  end

  # Exception raised when trying to refund a non refundable transaction.
  class NonRefundableTransactionException < BuckarooException
    attr_reader :transaction_id

    def initialize(transaction_id)
      @transaction_id = transaction_id

      message = "Not a refundable transaction: #{transaction_id}"
      super(message)
    end
  end

  # Exception raised when trying to cancel a non cancellable transaction.
  class NonCancellableTransactionException < BuckarooException
    attr_reader :transaction_id

    def initialize(transaction_id)
      @transaction_id = transaction_id

      message = "Not a cancellable transaction: #{transaction_id}"
      super(message)
    end
  end
end
