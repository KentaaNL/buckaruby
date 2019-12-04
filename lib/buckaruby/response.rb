# frozen_string_literal: true

require 'cgi'
require 'date'

module Buckaruby
  # Base class for any response.
  class Response
    attr_reader :params

    def initialize(body, config)
      @logger = config.logger

      @response = parse_response(body)
      @params = Support::CaseInsensitiveHash.new(@response)

      @logger.debug("[response] params: #{params.inspect}")

      verify_signature!(@response, config)
    end

    def status
      # See http://support.buckaroo.nl/index.php/Statuscodes
      case params[:brq_statuscode]
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

    def verify_signature!(response, config)
      if params[:brq_apiresult] != "Fail"
        sent_signature = params[:brq_signature]
        generated_signature = Signature.generate_signature(response, config)

        if sent_signature != generated_signature
          raise SignatureException.new(sent_signature, generated_signature)
        end
      end
    end

    def parse_time(time)
      time ? Time.strptime(time, '%Y-%m-%d %H:%M:%S') : nil
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
      if params[:brq_transaction_type] && !params[:brq_transaction_type].empty?
        # See http://support.buckaroo.nl/index.php/Transactietypes
        case params[:brq_transaction_type]
        when 'C021', 'V021',                                  # iDEAL
             'C002', 'C004', 'C005',                          # (SEPA) Direct Debit
             'V010', 'V014',                                  # PayPal
             'C090', 'V090',                                  # Bancontact
             'C001',                                          # Transfer

             'C044', 'C192', 'C283', 'C293', 'C318', 'C345',
             'C880', 'C963', 'V002', 'V032', 'V038', 'V044',
             'V192', 'V283', 'V293', 'V313', 'V318', 'V345',
             'V696',                                          # Visa

             'C043', 'C089', 'C273', 'C303', 'C328', 'C355',
             'C876', 'C969', 'V001', 'V031', 'V037', 'V043',
             'V089', 'V273', 'V303', 'V328', 'V355', 'V702',  # MasterCard

             'C046', 'C251', 'C288', 'C308', 'C333', 'C872',
             'C972', 'V034', 'V040', 'V046', 'V094', 'V245',
             'V288', 'V308', 'V333', 'V705',                  # Maestro

             'V003', 'V030', 'V036', 'V042'                   # American Express

          # Check the recurring flag to detect a normal or recurring transaction.
          if params[:brq_recurring] && params[:brq_recurring].casecmp("true").zero?
            TransactionType::PAYMENT_RECURRENT
          else
            TransactionType::PAYMENT
          end
        when 'C121',                                          # iDEAL
             'C102', 'C500',                                  # (SEPA) Direct Debit
             'V110',                                          # PayPal
             'C092', 'V092',                                  # Bancontact
             'C101',                                          # Transfer

             'C080', 'C194', 'C281', 'C290', 'C315', 'C342',
             'C881', 'C961', 'V068', 'V074', 'V080', 'V102',
             'V194', 'V281', 'V290', 'V315', 'V342', 'V694',  # Visa

             'C079', 'C197', 'C300', 'C325', 'C352', 'C371',
             'C877', 'C967', 'V067', 'V073', 'V079', 'V101',
             'V149', 'V197', 'V300', 'V325', 'V352', 'V371',
             'V700',                                          # MasterCard

             'C082', 'C252', 'C286', 'C305', 'C330', 'C873',
             'C970', 'V070', 'V076', 'V082', 'V246', 'V286',
             'V305', 'V330', 'V703',                          # Maestro

             'V066', 'V072', 'V078', 'V103'                   # American Express
          TransactionType::REFUND
        when 'C501', 'C502', 'C562',                          # (SEPA) Direct Debit
             'V111',                                          # PayPal

             'C554', 'C593', 'C882', 'V132', 'V138', 'V144',
             'V544', 'V592',                                  # Visa

             'C553', 'C589', 'C878', 'V131', 'V137', 'V143',
             'V543', 'V589',                                  # MasterCard

             'C546', 'C551', 'C874', 'V134', 'V140', 'V146',
             'V545', 'V546',                                  # Maestro

             'V130', 'V136', 'V142'                           # American Express
          TransactionType::REVERSAL
        end
      else
        # Fallback when transaction type is not known (cancelling credit card)
        TransactionType::PAYMENT
      end
    end

    def transaction_status
      status
    end

    def to_h
      hash = {
        account_bic: account_bic,
        account_iban: account_iban,
        account_name: account_name,
        collect_date: collect_date,
        invoicenumber: invoicenumber,
        mandate_reference: mandate_reference,
        payment_id: payment_id,
        payment_method: payment_method,
        refund_transaction_id: refund_transaction_id,
        reversal_transaction_id: reversal_transaction_id,
        timestamp: timestamp,
        transaction_id: transaction_id,
        transaction_type: transaction_type,
        transaction_status: transaction_status
      }.reject { |_key, value| value.nil? }

      hash
    end

    private

    def parse_date(date)
      date ? Date.strptime(date, '%Y-%m-%d') : nil
    end

    def parse_payment_method(method)
      method ? method.downcase : nil
    end
  end

  # Base class for a response via the API.
  class ApiResponse < Response
    def initialize(response, config)
      super(response, config)

      if params[:brq_apiresult].nil? || params[:brq_apiresult].casecmp("fail").zero?
        raise ApiException, params
      end
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
  end
end
