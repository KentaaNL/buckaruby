# frozen_string_literal: true

require 'date'

module Buckaruby
  # Base class for any response.
  class Response
    attr_reader :params

    def initialize(response, options)
      @params = Support::CaseInsensitiveHash.new(response)

      verify_signature!(response, options)
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

    private

    def verify_signature!(response, options)
      if params[:brq_apiresult] != "Fail"
        sent_signature = params[:brq_signature]
        generated_signature = Signature.generate_signature(response, options)

        if sent_signature != generated_signature
          raise SignatureException.new(sent_signature, generated_signature)
        end
      end
    end

    def parse_time(time)
      time ? Time.strptime(time, '%Y-%m-%d %H:%M:%S') : nil
    end
  end

  # Base class for a transaction response.
  class TransactionResponse < Response
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
        when 'C001', 'C002', 'C004', 'C021', 'C043', 'C044', 'C046', 'C089', 'C090', 'C192', 'C251', 'V001', 'V002', 'V010', 'V021', 'V032', 'V034', 'V043', 'V044', 'V046', 'V089', 'V090', 'V192', 'V245'
          # Check the recurring flag to detect a normal or recurring transaction.
          if params[:brq_recurring] && params[:brq_recurring].casecmp("true").zero?
            TransactionType::PAYMENT_RECURRENT
          else
            TransactionType::PAYMENT
          end
        when 'C005', 'V014', 'V031', 'V094'
          TransactionType::PAYMENT_RECURRENT
        when 'C079', 'C080', 'C082', 'C092', 'C101', 'C102', 'C121', 'C194', 'C197', 'C252', 'C500', 'V067', 'V068', 'V070', 'V079', 'V080', 'V082', 'V092', 'V101', 'V102', 'V110', 'V149', 'V194', 'V197', 'V246'
          TransactionType::REFUND
        when 'C501', 'C502', 'C546', 'C551', 'C553', 'C554', 'C562', 'C589', 'C593', 'V111', 'V131', 'V132', 'V134', 'V143', 'V144', 'V146', 'V543', 'V544', 'V545', 'V546', 'V589', 'V592'
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

  # Base class for a transaction response via the API.
  class TransactionApiResponse < TransactionResponse
    def initialize(response, options)
      super(response, options)

      if params[:brq_apiresult].nil? || params[:brq_apiresult] == "Fail"
        raise ApiException, params
      end
    end
  end

  # Response when creating a new transaction.
  class SetupTransactionResponse < TransactionApiResponse
  end

  # Response when creating a recurrent transaction.
  class RecurrentTransactionResponse < TransactionApiResponse
  end

  # Response when getting the status of a transaction.
  class StatusResponse < TransactionApiResponse
  end

  # Response when verifying the Buckaroo callback.
  class CallbackResponse < TransactionResponse
  end
end
