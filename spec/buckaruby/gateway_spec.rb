# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Gateway do
  describe 'initialization' do
    describe 'bad parameters' do
      it 'raises an exception when creating a new instance with invalid parameters' do
        expect {
          Buckaruby::Gateway.new
        }.to raise_error(ArgumentError)

        expect {
          Buckaruby::Gateway.new(website: "12345678")
        }.to raise_error(ArgumentError)

        expect {
          Buckaruby::Gateway.new(secret: "7C222FB2927D828AF22F592134E8932480637C0D")
        }.to raise_error(ArgumentError)

        expect {
          Buckaruby::Gateway.new(website: "", secret: "")
        }.to raise_error(ArgumentError)
      end
    end
  end

  subject { Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D") }

  it { expect(subject).to be_an_instance_of(Buckaruby::Gateway) }

  describe '#issuers' do
    context 'when no or false parameters are passed' do
      it 'raises an ArgumentError' do
        expect { subject.issuers }.to raise_error(ArgumentError)
        expect { subject.issuers(:wrong) }.to raise_error(ArgumentError)
      end
    end

    context 'when ideal is passed' do
      let(:issuers) { subject.issuers(Buckaruby::PaymentMethod::IDEAL) }

      it { expect(issuers.length).to be > 0 }
      it { expect(issuers).to include("INGBNL2A" => "ING") }
    end

    context 'when ideal processing is passed' do
      let(:issuers) { subject.issuers(Buckaruby::PaymentMethod::IDEAL_PROCESSING) }

      it { expect(issuers.length).to be > 0 }
      it { expect(issuers).to include("RABONL2U" => "Rabobank") }
    end

    context 'when visa, mastercard, maestro, bankcontact, sepa direct debit or paypal is passed' do
      it 'raises an ArgumentError' do
        expect { subject.issuers(Buckaruby::PaymentMethod::VISA) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::MASTER_CARD) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::MAESTRO) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::BANCONTACT_MISTER_CASH) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::PAYPAL) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#setup_transaction' do
    before do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_return(body: File.read("spec/fixtures/responses/setup_transaction_success.txt"))
    end

    it 'raises an exception when initiating a transaction with missing parameters' do
      expect {
        subject.setup_transaction(amount: 10)
      }.to raise_error(ArgumentError)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL)
      }.to raise_error(ArgumentError)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first)
      }.to raise_error(ArgumentError)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345")
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid amount' do
      expect {
        subject.setup_transaction(amount: 0, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)

      expect {
        subject.setup_transaction(amount: -1, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid payment method' do
      expect {
        subject.setup_transaction(amount: 10, payment_method: "abc", payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid payment issuer' do
      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: "abc", invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'raises a ConnectionException when connection the Buckaroo fails' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_raise(Errno::ECONNREFUSED)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(Buckaruby::ConnectionException)
    end

    it 'raises an InvalidResponseException when Buckaroo returns an invalid response' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_return(status: 500)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(Buckaruby::InvalidResponseException)
    end

    it 'raises an ApiException when API result Fail is returned' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_return(body: "BRQ_APIRESULT=Fail&BRQ_APIERRORMESSAGE=Invalid+request")

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(Buckaruby::ApiException)
    end

    describe 'initiates a transaction when amount is integer, decimal or string' do
      context 'when amount is an integer' do
        let(:response) { subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).not_to be nil }
      end

      context 'when amount is a decimal' do
        let(:response) { subject.setup_transaction(amount: 10.50, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).not_to be nil }
      end

      context 'when amount is a string' do
        let(:response) { subject.setup_transaction(amount: '10', payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).not_to be nil }
      end
    end

    it 'initiates a transaction for payment method ideal' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).not_to be nil
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'initiates a transaction for payment method visa' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).not_to be nil
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'initiates a transaction for payment method mastercard' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::MASTER_CARD, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).not_to be nil
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'initiates a transaction for payment method sepa direct debit' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT, invoicenumber: "12345", return_url: "http://www.return.url/", account_iban: "NL13TEST0123456789", account_name: "J. Tester", mandate_reference: "00P12345", collect_date: Date.new(2016, 1, 1))
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'initiates a transaction for payment method paypal' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::PAYPAL, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).not_to be nil
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    context 'with custom variables' do
      it 'sends the custom variables with the request' do
        response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: "ABNANL2A", invoicenumber: "12345", return_url: "http://www.return.url/", custom: { foo: :bar, quux: "42" })
        expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
        expect(response.custom[:foo]).to eq("bar")
        expect(response.custom[:quux]).to eq("42")

        expect(WebMock).to have_requested(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
          .with(body: "brq_websitekey=12345678&brq_payment_method=ideal&brq_culture=nl-NL&brq_currency=EUR&brq_amount=10.0&brq_invoicenumber=12345&brq_service_ideal_action=Pay&brq_service_ideal_issuer=ABNANL2A&brq_service_ideal_version=2&brq_return=http%3A%2F%2Fwww.return.url%2F&cust_foo=bar&cust_quux=42&add_buckaruby=Buckaruby+#{Buckaruby::VERSION}&brq_signature=0fb3ff3c1f140b5aede33a0fdacbc5675830120d")
      end
    end

    context 'with additional variables' do
      it 'sends the additional variables with the request' do
        response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: "ABNANL2A", invoicenumber: "12345", return_url: "http://www.return.url/", additional: { myreference: "12345" })
        expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
        expect(response.additional[:buckaruby]).to eq("1.2.0")
        expect(response.additional[:myreference]).to eq("12345")

        expect(WebMock).to have_requested(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
          .with(body: "brq_websitekey=12345678&brq_payment_method=ideal&brq_culture=nl-NL&brq_currency=EUR&brq_amount=10.0&brq_invoicenumber=12345&brq_service_ideal_action=Pay&brq_service_ideal_issuer=ABNANL2A&brq_service_ideal_version=2&brq_return=http%3A%2F%2Fwww.return.url%2F&add_myreference=12345&add_buckaruby=Buckaruby+#{Buckaruby::VERSION}&brq_signature=f7996840436bdd55dada28b80c62ed88af10cd23")
      end
    end
  end

  describe '#recurrent_transaction' do
    before do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_return(body: File.read("spec/fixtures/responses/recurrent_transaction_success.txt"))
    end

    it 'raises an exception when initiating a recurrent transaction with missing parameters' do
      expect {
        subject.recurrent_transaction(amount: 10)
      }.to raise_error(ArgumentError)

      expect {
        subject.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA)
      }.to raise_error(ArgumentError)

      expect {
        subject.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: "12345")
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid payment method' do
      expect {
        subject.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: "12345", transaction_id: "12345")
      }.to raise_error(ArgumentError)
    end

    it 'initiates a recurrent transaction for payment method visa' do
      response = subject.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: "12345", transaction_id: "12345")
      expect(response).to be_an_instance_of(Buckaruby::RecurrentTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::VISA)
      expect(response.invoicenumber).to eq("12345")
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end
  end

  describe '#refundable?' do
    it 'raises an exception when required parameters are missing' do
      expect {
        subject.refundable?
      }.to raise_error(ArgumentError)
    end

    it 'returns true when the transaction is refundable' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=RefundInfo").to_return(body: File.read("spec/fixtures/responses/refund_info_success.txt"))

      response = subject.refundable?(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response).to be true
    end

    it 'returns false when the transaction was not found' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=RefundInfo").to_return(body: File.read("spec/fixtures/responses/refund_info_error.txt"))

      response = subject.refundable?(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response).to be false
    end
  end

  describe '#refund_transaction' do
    it 'raises an exception when required parameters are missing' do
      expect {
        subject.refund_transaction
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when the transaction is not refundable' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=RefundInfo").to_return(body: File.read("spec/fixtures/responses/refund_info_error.txt"))

      expect {
        subject.refund_transaction(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      }.to raise_error(Buckaruby::NonRefundableTransactionException)
    end

    it 'refunds the transaction' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=RefundInfo").to_return(body: File.read("spec/fixtures/responses/refund_info_success.txt"))
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest").to_return(body: File.read("spec/fixtures/responses/refund_transaction_success.txt"))

      response = subject.refund_transaction(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq("8CCE4BB06339F28A506E1A328025D7DF13CCAD59")
      expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
      expect(response.refund_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.invoicenumber).to eq("12345")
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end
  end

  describe '#status' do
    before do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus").to_return(body: File.read("spec/fixtures/responses/status_success.txt"))
    end

    it 'raises an exception when required parameters are missing' do
      expect {
        subject.status
      }.to raise_error(ArgumentError)
    end

    it { expect(subject.status(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")).to be_an_instance_of(Buckaruby::StatusResponse) }

    it 'returns transaction status' do
      response = subject.status(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
      expect(response.invoicenumber).to eq("12345")
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'includes account iban, bic and name for an ideal response' do
      response = subject.status(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.account_iban).to eq("NL44RABO0123456789")
      expect(response.account_bic).to eq("RABONL2U")
      expect(response.account_name).to eq("J. de Tester")
    end
  end

  describe '#cancellable?' do
    it 'raises an exception when required parameters are missing' do
      expect {
        subject.cancellable?
      }.to raise_error(ArgumentError)
    end

    it 'returns true when the transaction is cancellable' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus").to_return(body: File.read("spec/fixtures/responses/status_cancellable.txt"))

      response = subject.cancellable?(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response).to be true
    end

    it 'returns false when the transaction is not cancellable' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus").to_return(body: File.read("spec/fixtures/responses/status_noncancellable.txt"))

      response = subject.cancellable?(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response).to be false
    end
  end

  describe '#cancel_transaction' do
    it 'raises an exception when required parameters are missing' do
      expect {
        subject.cancel_transaction
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when the transaction is not cancellable' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus").to_return(body: File.read("spec/fixtures/responses/status_noncancellable.txt"))

      expect {
        subject.cancel_transaction(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      }.to raise_error(Buckaruby::NonCancellableTransactionException)
    end

    it 'cancels the transaction' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus").to_return(body: File.read("spec/fixtures/responses/status_cancellable.txt"))
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=CancelTransaction").to_return(body: File.read("spec/fixtures/responses/cancel_success.txt"))

      response = subject.cancel_transaction(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response).to be_an_instance_of(Buckaruby::CancelResponse)
    end
  end

  describe '#callback' do
    it 'raises an exception when parameters are missing' do
      expect {
        subject.callback
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when parameter is an empty Hash' do
      expect {
        subject.callback({})
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when parameter is an empty String' do
      expect {
        subject.callback("")
      }.to raise_error(ArgumentError)
    end

    it 'raises a SignatureException when the signature is invalid' do
      params = File.read("spec/fixtures/responses/callback_invalid_signature.txt")

      expect {
        subject.callback(params)
      }.to raise_error(Buckaruby::SignatureException, "Sent signature (abcdefgh1234567890abcdefgh1234567890) doesn't match generated signature (0a74bba15fccd8094f33678c001b44851643876d)")
    end

    it 'returns the status when the signature is valid' do
      params = File.read("spec/fixtures/responses/callback_valid_signature.txt")

      response = subject.callback(params)
      expect(response).to be_an_instance_of(Buckaruby::CallbackResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
      expect(response.invoicenumber).to eq("12345")
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'accepts a Hash as parameters' do
      params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "0a74bba15fccd8094f33678c001b44851643876d" }

      response = subject.callback(params)
      expect(response).to be_an_instance_of(Buckaruby::CallbackResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
      expect(response.invoicenumber).to eq("12345")
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    context 'when callback is a payment response' do
      it 'sets the success status when payment status is success' do
        params = File.read("spec/fixtures/responses/callback_payment_success.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'sets the failed status when payment status is failed' do
        params = File.read("spec/fixtures/responses/callback_payment_failed.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::FAILED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'sets the rejected status when payment status is rejected' do
        params = File.read("spec/fixtures/responses/callback_payment_rejected.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::REJECTED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'sets the cancelled status when payment status is cancelled' do
        params = File.read("spec/fixtures/responses/callback_payment_cancelled.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::CANCELLED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'sets the pending status when payment status is pending' do
        params = File.read("spec/fixtures/responses/callback_payment_pending.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'includes account iban, bic and name for an ideal response' do
        params = File.read("spec/fixtures/responses/callback_payment_success.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.account_iban).to eq("NL44RABO0123456789")
        expect(response.account_bic).to eq("RABONL2U")
        expect(response.account_name).to eq("J. de Tester")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'includes account iban, name, mandate reference and collect date for a sepa direct debit response' do
        params = File.read("spec/fixtures/responses/callback_payment_sepa.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.account_iban).to eq("NL13TEST0123456789")
        expect(response.account_name).to eq("J. Tester")
        expect(response.mandate_reference).to eq("012345")
        expect(response.collect_date).to eq(Date.new(2014, 11, 13))
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'returns transaction type payment when cancelling a visa or mastercard transaction (empty transaction type)' do
        params = File.read("spec/fixtures/responses/callback_payment_empty_transaction_type.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::CANCELLED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'sets the transaction type to payment and payment method to American Express for amex callback' do
        params = File.read("spec/fixtures/responses/callback_payment_amex.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::AMERICAN_EXPRESS)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end
    end

    context 'when callback is a payment recurrent response' do
      it 'recognizes a visa payment recurrent response' do
        params = File.read("spec/fixtures/responses/callback_recurrent_visa.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT_RECURRENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::VISA)
        expect(response.transaction_id).to eq("B51118F58785274E117EFE1BF99D4D50CCB96949")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'recognizes a sepa direct debit payment recurrent response' do
        params = File.read("spec/fixtures/responses/callback_recurrent_sepa.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT_RECURRENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq("B51118F58785274E117EFE1BF99D4D50CCB96949")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end
    end

    context 'when callback is a refund response' do
      it 'recognizes an ideal refund response' do
        params = File.read("spec/fixtures/responses/callback_refund_ideal.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq("B51118F58785274E117EFE1BF99D4D50CCB96949")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.refund_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'recognizes a paypal refund response' do
        params = File.read("spec/fixtures/responses/callback_refund_paypal.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::PAYPAL)
        expect(response.transaction_id).to eq("B51118F58785274E117EFE1BF99D4D50CCB96949")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.refund_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'recognizes an amex refund response' do
        params = File.read("spec/fixtures/responses/callback_refund_amex.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::AMERICAN_EXPRESS)
        expect(response.transaction_id).to eq("B51118F58785274E117EFE1BF99D4D50CCB96949")
        expect(response.payment_id).to be nil
        expect(response.invoicenumber).to eq("12345")
        expect(response.refund_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end
    end

    context 'when callback is a reversal response' do
      it 'recognizes a sepa direct debit reversal response' do
        params = File.read("spec/fixtures/responses/callback_reversal_sepa.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REVERSAL)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq("8CCE4BB06339F28A506E1A328025D7DF13CCAD59")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.reversal_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end

      it 'recognizes a paypal reversal response' do
        params = File.read("spec/fixtures/responses/callback_reversal_paypal.txt")

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REVERSAL)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::PAYPAL)
        expect(response.transaction_id).to eq("8CCE4BB06339F28A506E1A328025D7DF13CCAD59")
        expect(response.payment_id).to eq("E86256B2787EE7FF0C33D0D4C6159CD922227B79")
        expect(response.invoicenumber).to eq("12345")
        expect(response.reversal_transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end
    end
  end
end
