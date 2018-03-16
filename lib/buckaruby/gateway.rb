# frozen_string_literal: true

require 'bigdecimal'
require 'logger'

module Buckaruby
  # Implementation of the BPE 3.0 NVP Gateway.
  class Gateway
    class << self
      # Buckaroo mode can be set as class setting
      attr_accessor :mode
    end

    attr_reader :options

    def initialize(options = {})
      validate_required_params!(options, :website, :secret)

      @logger = defined?(Rails) ? Rails.logger : Logger.new(STDOUT)
      @options = options

      set_buckaroo_mode!(@options)
      set_hash_method!(@options)
    end

    # Get a list with payment issuers.
    def issuers(payment_method)
      if payment_method != PaymentMethod::IDEAL && payment_method != PaymentMethod::IDEAL_PROCESSING
        raise ArgumentError, "Invalid payment method, only iDEAL is supported."
      end

      Ideal::ISSUERS
    end

    # Setup a new transaction.
    def setup_transaction(options = {})
      @logger.debug("[setup_transaction] options=#{options.inspect}")

      validate_setup_transaction_params!(options)

      normalize_account_iban!(options) if options[:payment_method] == PaymentMethod::SEPA_DIRECT_DEBIT

      execute_request(:setup_transaction, options)
    end

    # Setup a recurrent transaction.
    def recurrent_transaction(options = {})
      @logger.debug("[recurrent_transaction] options=#{options.inspect}")

      validate_recurrent_transaction_params!(options)

      execute_request(:recurrent_transaction, options)
    end

    # Checks if a transaction is refundable.
    def refundable?(options = {})
      @logger.debug("[refundable?] options=#{options.inspect}")

      validate_required_params!(options, :transaction_id)

      response = execute_request(:refund_info, options)
      response.refundable?
    end

    # Refund a transaction.
    def refund_transaction(options = {})
      @logger.debug("[refund_transaction] options=#{options.inspect}")

      validate_refund_transaction_params!(options)

      response = execute_request(:refund_info, options)
      unless response.refundable?
        raise NonRefundableTransactionException, options[:transaction_id]
      end

      # Pick maximum refundable amount if amount is not supplied.
      options[:amount] = response.maximum_amount unless options[:amount]

      # Fill required parameters with data from refund info request.
      options.merge!(
        payment_method: response.payment_method,
        invoicenumber: response.invoicenumber,
        currency: response.currency
      )

      execute_request(:refund_transaction, options)
    end

    # Get transaction status.
    def status(options = {})
      @logger.debug("[status] options=#{options.inspect}")

      validate_status_params!(options)

      execute_request(:status, options)
    end

    # Checks if a transaction is cancellable.
    def cancellable?(options = {})
      @logger.debug("[cancellable?] options=#{options.inspect}")

      validate_required_params!(options, :transaction_id)

      response = execute_request(:status, options)
      response.cancellable?
    end

    # Cancel a transaction.
    def cancel_transaction(options = {})
      @logger.debug("[cancel_transaction] options=#{options.inspect}")

      validate_required_params!(options, :transaction_id)

      response = execute_request(:status, options)
      unless response.cancellable?
        raise NonCancellableTransactionException, options[:transaction_id]
      end

      execute_request(:cancel, options)
    end

    # Verify the response / callback.
    def callback(response = {})
      if response.empty?
        raise ArgumentError, "No callback parameters found"
      end

      CallbackResponse.new(response, @options)
    end

    private

    # Validate required parameters.
    def validate_required_params!(params, *required)
      required.flatten.each do |param|
        if !params.key?(param) || params[param].to_s.empty?
          raise ArgumentError, "Missing required parameter: #{param}."
        end
      end
    end

    # Validate params for setup transaction.
    def validate_setup_transaction_params!(options)
      required_params = [:amount, :payment_method, :invoicenumber]
      required_params << :return_url if options[:payment_method] != PaymentMethod::SEPA_DIRECT_DEBIT

      case options[:payment_method]
      when PaymentMethod::IDEAL, PaymentMethod::IDEAL_PROCESSING
        required_params << :payment_issuer
      when PaymentMethod::SEPA_DIRECT_DEBIT
        required_params << [:account_iban, :account_name]
      end

      validate_required_params!(options, required_params)

      validate_amount!(options)

      valid_payment_methods = [
        PaymentMethod::IDEAL, PaymentMethod::IDEAL_PROCESSING, PaymentMethod::VISA, PaymentMethod::MASTER_CARD, PaymentMethod::MAESTRO,
        PaymentMethod::SEPA_DIRECT_DEBIT, PaymentMethod::PAYPAL, PaymentMethod::BANCONTACT_MISTER_CASH
      ]
      validate_payment_method!(options, valid_payment_methods)

      validate_payment_issuer!(options)
    end

    # Validate amount of money, must be greater than 0.
    def validate_amount!(options)
      money = BigDecimal.new(options[:amount].to_s)
      if money <= 0
        raise ArgumentError, "Invalid amount: #{options[:amount]} (must be greater than 0)"
      end
    end

    # Validate the payment method.
    def validate_payment_method!(options, valid)
      unless valid.include?(options[:payment_method])
        raise ArgumentError, "Invalid payment method: #{options[:payment_method]}"
      end
    end

    # Validate the payment issuer when iDEAL is selected as payment method.
    def validate_payment_issuer!(options)
      if options[:payment_method] == PaymentMethod::IDEAL || options[:payment_method] == PaymentMethod::IDEAL_PROCESSING
        unless Ideal::ISSUERS.include?(options[:payment_issuer])
          raise ArgumentError, "Invalid payment issuer: #{options[:payment_issuer]}"
        end
      end
    end

    # Validate params for recurrent transaction.
    def validate_recurrent_transaction_params!(options)
      required_params = [:amount, :payment_method, :invoicenumber, :transaction_id]

      validate_required_params!(options, required_params)

      validate_amount!(options)

      valid_payment_methods = [
        PaymentMethod::VISA, PaymentMethod::MASTER_CARD, PaymentMethod::MAESTRO,
        PaymentMethod::SEPA_DIRECT_DEBIT, PaymentMethod::PAYPAL
      ]
      validate_payment_method!(options, valid_payment_methods)
    end

    # Validate params for refund transaction.
    def validate_refund_transaction_params!(options)
      unless options[:transaction_id]
        raise ArgumentError, "Missing required parameter: transaction_id"
      end

      if options[:amount]
        validate_amount!(options)
      end
    end

    # Validate params for transaction status.
    def validate_status_params!(options)
      if !options[:transaction_id] && !options[:payment_id]
        raise ArgumentError, "Missing parameters: transaction_id or payment_id should be present"
      end
    end

    # Strip spaces from the IBAN.
    def normalize_account_iban!(options)
      iban = options[:account_iban].to_s.gsub(/\s/, "")

      options[:account_iban] = iban
    end

    # Set Buckaroo mode from options, class setting or the default (test).
    def set_buckaroo_mode!(options)
      mode = options.key?(:mode) ? options[:mode] : Gateway.mode
      mode ||= :test

      if mode != :test && mode != :production
        raise ArgumentError, "Invalid Buckaroo mode provided: #{mode} (expected :test or :production)"
      end

      options[:mode] = mode
    end

    # Set the hash method from options or default (SHA-1).
    def set_hash_method!(options)
      hash_method = (options[:hash_method] || "SHA1").downcase.to_sym

      unless [:sha1, :sha256, :sha512].include?(hash_method)
        raise ArgumentError, "Invalid hash method provided: #{options[:hash_method]} (expected :sha1, :sha256 or :sha512)"
      end

      options[:hash_method] = hash_method
    end

    # Build and execute a request.
    def execute_request(request_type, options)
      request = build_request(request_type)
      response = request.execute(options)

      case request_type
      when :setup_transaction
        SetupTransactionResponse.new(response, @options)
      when :recurrent_transaction
        RecurrentTransactionResponse.new(response, @options)
      when :refund_transaction
        RefundTransactionResponse.new(response, @options)
      when :refund_info
        RefundInfoResponse.new(response, @options)
      when :status
        StatusResponse.new(response, @options)
      when :cancel
        CancelResponse.new(response, @options)
      end
    end

    # Factory method for constructing a request.
    def build_request(request_type)
      case request_type
      when :setup_transaction
        SetupTransactionRequest.new(@options)
      when :recurrent_transaction
        RecurrentTransactionRequest.new(@options)
      when :refund_transaction
        RefundTransactionRequest.new(@options)
      when :refund_info
        RefundInfoRequest.new(@options)
      when :status
        StatusRequest.new(@options)
      when :cancel
        CancelRequest.new(@options)
      end
    end
  end
end
