# frozen_string_literal: true

require_relative 'support/case_insensitive_hash'

require 'cgi'
require 'date'

module Buckaruby
  # Base class for any response.
  class Response
    attr_reader :response

    def initialize(body, config)
      @response = parse_response(body)

      logger = config.logger
      logger.debug("[response] params: #{params.inspect}")
    end

    def params
      @params ||= Support::CaseInsensitiveHash.new(response)
    end

    def status
      TransactionStatus.parse(params[:brq_statuscode])
    end

    def timestamp
      parse_time(params[:brq_timestamp])
    end

    def custom
      @custom ||= begin
        custom = Support::CaseInsensitiveHash.new

        params.each do |key, value|
          next unless key.upcase.start_with?("CUST_")

          new_key = key.to_s[5..-1]
          custom[new_key] = value
        end

        custom
      end
    end

    def additional
      @additional ||= begin
        additional = Support::CaseInsensitiveHash.new

        params.each do |key, value|
          next unless key.upcase.start_with?("ADD_")

          new_key = key.to_s[4..-1]
          additional[new_key] = value
        end

        additional
      end
    end

    private

    def parse_response(body)
      if body.is_a?(Hash)
        response = body
      else
        response = CGI.parse(body)
        response.each { |key, value| response[key] = value.first }
      end

      response
    end

    def parse_time(time)
      Time.strptime(time, '%Y-%m-%d %H:%M:%S') if time
    end
  end

  # Base for a transaction response.
  module TransactionResponse
    def account_bic
      case payment_method
      when PaymentMethod::IDEAL
        params[:brq_service_ideal_consumerbic]
      when PaymentMethod::IDEAL_PROCESSING
        params[:brq_service_idealprocessing_consumerbic]
      when PaymentMethod::SEPA_DIRECT_DEBIT
        params[:brq_service_sepadirectdebit_customerbic]
      end
    end

    def account_iban
      case payment_method
      when PaymentMethod::IDEAL
        params[:brq_service_ideal_consumeriban]
      when PaymentMethod::IDEAL_PROCESSING
        params[:brq_service_idealprocessing_consumeriban]
      when PaymentMethod::SEPA_DIRECT_DEBIT
        params[:brq_service_sepadirectdebit_customeriban]
      end
    end

    def account_name
      case payment_method
      when PaymentMethod::IDEAL
        params[:brq_service_ideal_consumername] || params[:brq_customer_name]
      when PaymentMethod::IDEAL_PROCESSING
        params[:brq_service_idealprocessing_consumername] || params[:brq_customer_name]
      when PaymentMethod::SEPA_DIRECT_DEBIT
        params[:brq_service_sepadirectdebit_customername] || params[:brq_customer_name]
      end
    end

    def collect_date
      if payment_method == PaymentMethod::SEPA_DIRECT_DEBIT
        parse_date(params[:brq_service_sepadirectdebit_collectdate])
      end
    end

    def invoicenumber
      params[:brq_invoicenumber]
    end

    def mandate_reference
      if payment_method == PaymentMethod::SEPA_DIRECT_DEBIT
        params[:brq_service_sepadirectdebit_mandatereference]
      end
    end

    def payment_id
      params[:brq_payment]
    end

    def payment_method
      parse_payment_method(params[:brq_payment_method] || params[:brq_transaction_method])
    end

    def redirect_url
      params[:brq_redirecturl]
    end

    def refund_transaction_id
      params[:brq_relatedtransaction_refund]
    end

    def reversal_transaction_id
      params[:brq_relatedtransaction_reversal]
    end

    def transaction_id
      params[:brq_transactions]
    end

    def transaction_type
      TransactionType.parse(params[:brq_transaction_type], params[:brq_recurring])
    end

    def transaction_status
      status
    end

    private

    def parse_date(date)
      Date.strptime(date, '%Y-%m-%d') if date
    end

    def parse_payment_method(method)
      method.downcase if method
    end
  end

  # Base class for a response via the API.
  class ApiResponse < Response
    def initialize(body, config)
      super(body, config)

      if api_result.nil? || api_result.casecmp("fail").zero?
        raise ApiException, params
      end

      Signature.verify!(config, response)
    end

    private

    def api_result
      params[:brq_apiresult]
    end
  end

  # Response when creating a new transaction.
  class SetupTransactionResponse < ApiResponse
    include TransactionResponse
  end

  # Response when creating a recurrent transaction.
  class RecurrentTransactionResponse < ApiResponse
    include TransactionResponse
  end

  # Response when creating a refund transaction.
  class RefundTransactionResponse < ApiResponse
    include TransactionResponse
  end

  # Response when retrieving the refund information.
  class RefundInfoResponse < ApiResponse
    def payment_method
      params[:brq_refundinfo_1_servicecode]
    end

    def refundable?
      !params[:brq_refundinfo_1_isrefundable].nil? && params[:brq_refundinfo_1_isrefundable].casecmp("true").zero?
    end

    def maximum_amount
      params[:brq_refundinfo_1_maximumrefundamount]
    end

    def invoicenumber
      params[:brq_refundinfo_1_invoice]
    end

    def currency
      params[:brq_refundinfo_1_refundcurrency]
    end
  end

  # Response when getting the status of a transaction.
  class StatusResponse < ApiResponse
    include TransactionResponse

    def cancellable?
      !params[:brq_transaction_cancelable].nil? && params[:brq_transaction_cancelable].casecmp("true").zero?
    end
  end

  # Response when cancelling a transaction.
  class CancelResponse < ApiResponse
  end

  # Response when verifying the Buckaroo callback.
  class CallbackResponse < Response
    include TransactionResponse

    def initialize(body, config)
      super(body, config)

      Signature.verify!(config, response)
    end
  end

  # Response when retrieving the specification for a transaction.
  class TransactionSpecificationResponse < ApiResponse
    def services
      @services ||= FieldMapper.map_fields(params, :brq_services)
    end

    def basic_fields
      @basic_fields ||= FieldMapper.map_fields(params, :brq_basicfields)
    end

    def custom_parameters
      @custom_parameters ||= FieldMapper.map_fields(params, :brq_customparameters)
    end
  end
end
