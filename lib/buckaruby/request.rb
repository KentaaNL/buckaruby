# frozen_string_literal: true

require 'date'
require 'net/http'
require 'openssl'
require 'uri'

module Buckaruby
  # Base class for any request.
  class Request
    def initialize(config)
      @config = config
    end

    def execute(options)
      uri = URI.parse(@config.api_url)
      uri.query = URI.encode_www_form(op: operation) if operation

      post_buckaroo(uri, build_request_data(options))
    end

    # Returns the service operation for this request.
    def operation
      nil
    end

    # Returns the request parameters (to be implemented by subclasses).
    def build_request_params(_options)
      raise NotImplementedError
    end

    private

    def post_buckaroo(uri, params)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == 'https'
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      raw_response = http.post(uri.request_uri, URI.encode_www_form(params))

      unless raw_response.is_a?(Net::HTTPSuccess)
        raise InvalidResponseException, raw_response
      end

      raw_response.body

    # Try to catch some common exceptions Net::HTTP might raise
    rescue Errno::ETIMEDOUT, Errno::EINVAL, Errno::ECONNRESET, Errno::ECONNREFUSED, Errno::EHOSTUNREACH,
           IOError, SocketError, Net::HTTPBadResponse, Net::HTTPHeaderSyntaxError, Net::OpenTimeout,
           Net::ProtocolError, Net::ReadTimeout, OpenSSL::SSL::SSLError => e
      raise ConnectionException, e
    end

    def build_request_data(options)
      params = { brq_websitekey: @config.website }

      params.merge!(build_request_params(options))
      params.merge!(build_custom_params(options[:custom])) if options[:custom]
      params.merge!(build_additional_params(options[:additional])) if options[:additional]

      params[:add_buckaruby] = "Buckaruby #{Buckaruby::VERSION}"

      # Sign the data with our secret key.
      params[:brq_signature] = Signature.generate(@config, params)

      params
    end

    def build_custom_params(options)
      options.transform_keys { |key| :"cust_#{key}" }
    end

    def build_additional_params(options)
      options.transform_keys { |key| :"add_#{key}" }
    end
  end

  # Base class for a transaction request.
  class TransactionRequest < Request
    def operation
      Operation::TRANSACTION_REQUEST
    end

    def build_request_params(options)
      params = {
        brq_payment_method: options[:payment_method],
        brq_culture: options[:culture] || Language::DUTCH,
        brq_currency: options[:currency] || Currency::EURO,
        brq_amount: Amount.new(options[:amount]).to_s,
        brq_invoicenumber: options[:invoicenumber]
      }

      params.merge!(build_transaction_request_params(options))

      params[:brq_clientip] = options[:client_ip] if options[:client_ip]
      params[:brq_description] = options[:description] if options[:description]
      params[:brq_return] = options[:return_url] if options[:return_url]

      params
    end

    def build_transaction_request_params(_options)
      raise NotImplementedError
    end
  end

  # Request for a creating a new transaction.
  class SetupTransactionRequest < TransactionRequest
    def build_transaction_request_params(options)
      params = {}

      case options[:payment_method]
      when PaymentMethod::IDEAL
        params.merge!(
          brq_service_ideal_action: Action::PAY,
          brq_service_ideal_issuer: options[:issuer],
          brq_service_ideal_version: '2'
        )
      when PaymentMethod::IDEAL_PROCESSING
        params.merge!(
          brq_service_idealprocessing_action: Action::PAY,
          brq_service_idealprocessing_issuer: options[:issuer],
          brq_service_idealprocessing_version: '2'
        )
      when PaymentMethod::SEPA_DIRECT_DEBIT
        params.merge!(
          brq_service_sepadirectdebit_action: Action::PAY,
          brq_service_sepadirectdebit_customeriban: options[:consumer_iban],
          brq_service_sepadirectdebit_customeraccountname: options[:consumer_name]
        )

        if options[:consumer_bic]
          params[:brq_service_sepadirectdebit_customerbic] = options[:consumer_bic]
        end

        if options[:collect_date]
          params[:brq_service_sepadirectdebit_collectdate] = options[:collect_date].strftime('%Y-%m-%d')
        end

        if options[:mandate_reference]
          params.merge!(
            brq_service_sepadirectdebit_action: [Action::PAY, Action::EXTRA_INFO].join(','),
            brq_service_sepadirectdebit_mandatereference: options[:mandate_reference],
            brq_service_sepadirectdebit_mandatedate: Date.today.strftime('%Y-%m-%d')
          )
        end
      end

      params[:brq_startrecurrent] = options[:recurring] if options[:recurring]

      params
    end
  end

  # Request for a creating a recurrent transaction.
  class RecurrentTransactionRequest < TransactionRequest
    def build_transaction_request_params(options)
      params = {}

      key = :"brq_service_#{options[:payment_method]}_action"
      params[key] = Action::PAY_RECURRENT

      # Indicate that this is a request without user redirection to a webpage.
      # This is needed to make recurrent payments working.
      params[:brq_channel] = 'backoffice'

      params[:brq_originaltransaction] = options[:transaction_id]

      params
    end
  end

  # Request for a creating a transaction specification.
  class TransactionSpecificationRequest < Request
    def operation
      Operation::TRANSACTION_REQUEST_SPECIFICATION
    end

    def build_request_params(options)
      params = {}

      if options[:payment_method]
        params[:brq_services] =
          if options[:payment_method].respond_to?(:join)
            options[:payment_method].join(',')
          else
            options[:payment_method]
          end
      end

      params[:brq_latestversiononly] = 'true'
      params[:brq_culture] = options[:culture] || Language::DUTCH

      params
    end
  end

  # Request for a creating a refund.
  class RefundTransactionRequest < Request
    def operation
      Operation::TRANSACTION_REQUEST
    end

    def build_request_params(options)
      params = {
        brq_payment_method: options[:payment_method],
        brq_amount_credit: Amount.new(options[:amount]).to_s,
        brq_currency: options[:currency] || Currency::EURO,
        brq_invoicenumber: options[:invoicenumber]
      }

      key = :"brq_service_#{options[:payment_method]}_action"
      params[key] = Action::REFUND

      params[:brq_originaltransaction] = options[:transaction_id]

      params
    end
  end

  # Request for retrieving refund information.
  class RefundInfoRequest < Request
    def operation
      Operation::REFUND_INFO
    end

    def build_request_params(options)
      params = {}

      params[:brq_transaction] = options[:transaction_id]

      params
    end
  end

  # Request for getting the status of a transaction.
  class StatusRequest < Request
    def operation
      Operation::TRANSACTION_STATUS
    end

    def build_request_params(options)
      params = {}

      params[:brq_transaction] = options[:transaction_id] if options[:transaction_id]
      params[:brq_payment] = options[:payment_id] if options[:payment_id]

      params
    end
  end

  # Request for cancelling a transaction.
  class CancelRequest < Request
    def operation
      Operation::CANCEL_TRANSACTION
    end

    def build_request_params(options)
      { brq_transaction: options[:transaction_id] }
    end
  end
end
