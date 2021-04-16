# frozen_string_literal: true

require 'bigdecimal'
require 'cgi'
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
      uri.query = "op=#{options[:operation]}" if options[:operation]

      post_buckaroo(uri, build_request_data(options))
    end

    def build_request_params(_options)
      raise NotImplementedError
    end

    private

    def post_buckaroo(uri, params)
      http = Net::HTTP.new(uri.host, uri.port)
      if uri.scheme == "https"
        http.use_ssl = true
        http.verify_mode = OpenSSL::SSL::VERIFY_PEER
      end

      raw_response = http.post(uri.request_uri, post_data(params))

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
      params[:brq_signature] = Signature.generate_signature(params, @config)

      params
    end

    def build_custom_params(options)
      options.map { |key, value| [:"cust_#{key}", value] }.to_h
    end

    def build_additional_params(options)
      options.map { |key, value| [:"add_#{key}", value] }.to_h
    end

    def post_data(params)
      params.map { |key, value| "#{key}=#{CGI.escape(value.to_s)}" }.join("&")
    end
  end

  # Base class for a transaction request.
  class TransactionRequest < Request
    def execute(options)
      super(options.merge(operation: Operation::TRANSACTION_REQUEST))
    end

    def build_request_params(options)
      params = {
        brq_payment_method: options[:payment_method],
        brq_culture: options[:culture] || Language::DUTCH,
        brq_currency: options[:currency] || Currency::EURO,
        brq_amount: BigDecimal(options[:amount].to_s).to_s("F"),
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
          brq_service_ideal_issuer: options[:payment_issuer],
          brq_service_ideal_version: "2"
        )
      when PaymentMethod::IDEAL_PROCESSING
        params.merge!(
          brq_service_idealprocessing_action: Action::PAY,
          brq_service_idealprocessing_issuer: options[:payment_issuer],
          brq_service_idealprocessing_version: "2"
        )
      when PaymentMethod::SEPA_DIRECT_DEBIT
        params.merge!(
          brq_service_sepadirectdebit_action: Action::PAY,
          brq_service_sepadirectdebit_customeriban: options[:account_iban],
          brq_service_sepadirectdebit_customeraccountname: options[:account_name]
        )

        if options[:account_bic]
          params[:brq_service_sepadirectdebit_customerbic] = options[:account_bic]
        end

        if options[:collect_date]
          params[:brq_service_sepadirectdebit_collectdate] = options[:collect_date].strftime("%Y-%m-%d")
        end

        if options[:mandate_reference]
          params.merge!(
            brq_service_sepadirectdebit_action: [Action::PAY, Action::EXTRA_INFO].join(","),
            brq_service_sepadirectdebit_mandatereference: options[:mandate_reference],
            brq_service_sepadirectdebit_mandatedate: Date.today.strftime("%Y-%m-%d")
          )
        end
      end

      params[:brq_startrecurrent] = options[:recurring] if options[:recurring]

      params
    end
  end

  # Request for a creating a transaction specification.
  class TransactionSpecificationRequest < Request
    def execute(options)
      super(options.merge(operation: Operation::TRANSACTION_REQUEST_SPECIFICATION))
    end

    def build_request_params(options)
      params = {}

      if options[:payment_method]
        if options[:payment_method].respond_to?(:join)
          params[:brq_services] = options[:payment_method].join(",")
        else
          params[:brq_services] = options[:payment_method]
        end
      end

      params[:brq_latestversiononly] = "true"
      params[:brq_culture] = options[:culture] || Language::DUTCH

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
      params[:brq_channel] = "backoffice"

      params[:brq_originaltransaction] = options[:transaction_id]

      params
    end
  end

  # Request for a creating a refund.
  class RefundTransactionRequest < Request
    def execute(options)
      super(options.merge(operation: Operation::TRANSACTION_REQUEST))
    end

    def build_request_params(options)
      params = {
        brq_payment_method: options[:payment_method],
        brq_amount_credit: BigDecimal(options[:amount].to_s).to_s("F"),
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
    def execute(options)
      super(options.merge(operation: Operation::REFUND_INFO))
    end

    def build_request_params(options)
      params = {}

      params[:brq_transaction] = options[:transaction_id]

      params
    end
  end

  # Request for getting the status of a transaction.
  class StatusRequest < Request
    def execute(options)
      super(options.merge(operation: Operation::TRANSACTION_STATUS))
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
    def execute(options)
      super(options.merge(operation: Operation::CANCEL_TRANSACTION))
    end

    def build_request_params(options)
      { brq_transaction: options[:transaction_id] }
    end
  end

  # Request for a "Data request".
  class DataRequest < Request
    def execute(options)
      super(options.merge(operation: Operation::DATA_REQUEST))
    end

    def build_request_params(options)
      params = { brq_payment_method: options[:service] }

      case options[:service]
      when Service::IDEAL_QR
        params.merge!(build_idealqr_params(options))
      end

      params
    end

    private

    def build_idealqr_params(options)
      params = {
        brq_service_idealqr_action: Action::GENERATE,
        brq_service_idealqr_description: options[:description],
        brq_service_idealqr_amount: BigDecimal(options[:amount].to_s).to_s("F"),
        brq_service_idealqr_purchaseid: options[:purchase_id],
        brq_service_idealqr_expiration: options[:expires_at].strftime("%Y-%m-%d")
      }

      # These parameters are mandatory, but we provide a default value.
      if options.key?(:oneoff)
        params[:brq_service_idealqr_isoneoff] = options[:oneoff]
      else
        params[:brq_service_idealqr_isoneoff] = false
      end

      if options.key?(:amount_changeable)
        params[:brq_service_idealqr_amountischangeable] = options[:amount_changeable]
      else
        params[:brq_service_idealqr_amountischangeable] = false
      end

      if options.key?(:image_size)
        params[:brq_service_idealqr_imagesize] = options[:image_size]
      else
        params[:brq_service_idealqr_imagesize] = 100
      end

      # Optional parameters.
      params[:brq_service_idealqr_isprocessing] = options[:processing] if options.key?(:processing)
      params[:brq_service_idealqr_minamount] = options[:minimum_amount] if options.key?(:minimum_amount)
      params[:brq_service_idealqr_maxamount] = options[:maximum_amount] if options.key?(:maximum_amount)

      params
    end
  end
end
