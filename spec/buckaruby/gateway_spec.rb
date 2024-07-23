# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Gateway do
  subject(:gateway) { Buckaruby::Gateway.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D') }

  it { expect(gateway).to be_an_instance_of(Buckaruby::Gateway) }

  describe '#payment_methods' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequestSpecification').to_return(body: File.read('spec/fixtures/responses/specify_transaction_success.txt'))
    end

    it 'returns the payment methods enabled by Buckaroo and supported by this library' do
      payment_methods = gateway.payment_methods
      expect(payment_methods).to eq([Buckaruby::PaymentMethod::IDEAL, Buckaruby::PaymentMethod::VISA])
    end
  end

  describe '#issuers' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequestSpecification').to_return(body: File.read('spec/fixtures/responses/specify_transaction_success.txt'))
    end

    context 'when no or false parameters are passed' do
      it 'raises an ArgumentError' do
        expect { gateway.issuers }.to raise_error(ArgumentError)
        expect { gateway.issuers(:wrong) }.to raise_error(ArgumentError)
      end
    end

    context 'when ideal is passed' do
      let(:issuers) { gateway.issuers(Buckaruby::PaymentMethod::IDEAL) }

      it 'returns the list with issuers' do
        expect(issuers).to eq({
                                'ABNANL2A' => 'ABN AMRO',
                                'ASNBNL21' => 'ASN Bank',
                                'BUNQNL2A' => 'bunq',
                                'FVLBNL22' => 'Van Lanschot',
                                'HANDNL2A' => 'Handelsbanken',
                                'INGBNL2A' => 'ING',
                                'KNABNL2H' => 'Knab',
                                'MOYONL21' => 'Moneyou',
                                'RABONL2U' => 'Rabobank',
                                'RBRBNL21' => 'RegioBank',
                                'SNSBNL2A' => 'SNS',
                                'TRIONL2U' => 'Triodos Bank'
                              })
      end
    end

    context 'when ideal processing is passed' do
      let(:issuers) { gateway.issuers(Buckaruby::PaymentMethod::IDEAL_PROCESSING) }

      it 'returns the list with issuers' do
        expect(issuers).to eq({
                                'ABNANL2A' => 'ABN AMRO',
                                'ASNBNL21' => 'ASN Bank',
                                'BUNQNL2A' => 'bunq',
                                'FVLBNL22' => 'Van Lanschot',
                                'HANDNL2A' => 'Handelsbanken',
                                'INGBNL2A' => 'ING',
                                'KNABNL2H' => 'Knab',
                                'MOYONL21' => 'Moneyou',
                                'RABONL2U' => 'Rabobank',
                                'RBRBNL21' => 'RegioBank',
                                'SNSBNL2A' => 'SNS',
                                'TRIONL2U' => 'Triodos Bank'
                              })
      end
    end

    context 'when a payment method other than ideal is passed' do
      it 'raises an ArgumentError' do
        expect { gateway.issuers(Buckaruby::PaymentMethod::VISA) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::MASTER_CARD) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::MAESTRO) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::AMERICAN_EXPRESS) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::BANCONTACT) }.to raise_error(ArgumentError)
        expect { gateway.issuers(Buckaruby::PaymentMethod::PAYPAL) }.to raise_error(ArgumentError)
      end
    end
  end

  describe '#setup_transaction' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(body: File.read('spec/fixtures/responses/setup_transaction_success.txt'))
    end

    it 'raises an exception when initiating a transaction with missing parameters' do
      expect {
        gateway.setup_transaction(amount: 10)
      }.to raise_error(ArgumentError)

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL)
      }.to raise_error(ArgumentError)

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345')
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid amount' do
      expect {
        gateway.setup_transaction(amount: 0, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(ArgumentError)

      expect {
        gateway.setup_transaction(amount: -1, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(ArgumentError)

      expect {
        gateway.setup_transaction(amount: 'abc', payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid payment method' do
      expect {
        gateway.setup_transaction(amount: 10, payment_method: 'abc', invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(ArgumentError)
    end

    it 'raises a ConnectionException when connection the Buckaroo fails' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_raise(Errno::ECONNREFUSED)

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(Buckaruby::ConnectionException)
    end

    it 'raises an InvalidResponseException when Buckaroo returns an invalid response' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(status: 500)

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(Buckaruby::InvalidResponseException)
    end

    it 'raises an ApiException when empty body is returned' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(body: '')

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(Buckaruby::ApiException)
    end

    it 'raises an ApiException when API result Fail is returned' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(body: 'BRQ_APIRESULT=Fail&BRQ_APIERRORMESSAGE=Invalid+request')

      expect {
        gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      }.to raise_error(Buckaruby::ApiException)
    end

    describe 'initiates a transaction when amount is integer, decimal or string' do
      context 'when amount is an integer' do
        let(:response) { gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/') }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24') }
        it { expect(response.redirect_url).not_to be_nil }
      end

      context 'when amount is a decimal' do
        let(:response) { gateway.setup_transaction(amount: 10.50, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/') }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24') }
        it { expect(response.redirect_url).not_to be_nil }
      end

      context 'when amount is a string' do
        let(:response) { gateway.setup_transaction(amount: '10', payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/') }

        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24') }
        it { expect(response.redirect_url).not_to be_nil }
      end
    end

    it 'initiates a transaction for payment method ideal' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method visa' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method mastercard' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::MASTER_CARD, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method sepa direct debit' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT, invoicenumber: '12345', return_url: 'http://www.return.url/', consumer_iban: 'NL13TEST0123456789', consumer_name: 'J. Tester', mandate_reference: '00P12345', collect_date: Date.new(2016, 1, 1))
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method paypal' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::PAYPAL, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method sofort' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::SOFORT, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'initiates a transaction for payment method giropay' do
      response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::GIROPAY, invoicenumber: '12345', return_url: 'http://www.return.url/')
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.redirect_url).not_to be_nil
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    context 'with custom variables' do
      it 'sends the custom variables with the request' do
        response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, issuer: 'ABNANL2A', invoicenumber: '12345', return_url: 'http://www.return.url/', custom: { foo: :bar, quux: '42' })
        expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
        expect(response.custom[:foo]).to eq('bar')
        expect(response.custom[:quux]).to eq('42')

        expect(WebMock).to have_requested(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest')
          .with(body: "brq_websitekey=12345678&brq_payment_method=ideal&brq_culture=nl-NL&brq_currency=EUR&brq_amount=10.00&brq_invoicenumber=12345&brq_service_ideal_action=Pay&brq_service_ideal_issuer=ABNANL2A&brq_service_ideal_version=2&brq_return=http%3A%2F%2Fwww.return.url%2F&cust_foo=bar&cust_quux=42&add_buckaruby=Buckaruby+#{Buckaruby::VERSION}&brq_signature=85b2dc9adcad13e19093f6edec750858136fe30d")
      end
    end

    context 'with additional variables' do
      it 'sends the additional variables with the request' do
        response = gateway.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, issuer: 'ABNANL2A', invoicenumber: '12345', return_url: 'http://www.return.url/', additional: { myreference: '12345' })
        expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
        expect(response.additional[:buckaruby]).to eq('1.2.0')
        expect(response.additional[:myreference]).to eq('12345')

        expect(WebMock).to have_requested(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest')
          .with(body: "brq_websitekey=12345678&brq_payment_method=ideal&brq_culture=nl-NL&brq_currency=EUR&brq_amount=10.00&brq_invoicenumber=12345&brq_service_ideal_action=Pay&brq_service_ideal_issuer=ABNANL2A&brq_service_ideal_version=2&brq_return=http%3A%2F%2Fwww.return.url%2F&add_myreference=12345&add_buckaruby=Buckaruby+#{Buckaruby::VERSION}&brq_signature=1ab3d01ea98e6b0aafb75b53c9e025f3ecc6d81b")
      end
    end
  end

  describe '#recurrent_transaction' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(body: File.read('spec/fixtures/responses/recurrent_transaction_success.txt'))
    end

    it 'raises an exception when initiating a recurrent transaction with missing parameters' do
      expect {
        gateway.recurrent_transaction(amount: 10)
      }.to raise_error(ArgumentError)

      expect {
        gateway.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA)
      }.to raise_error(ArgumentError)

      expect {
        gateway.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: '12345')
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when initiating a transaction with invalid payment method' do
      expect {
        gateway.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: '12345', transaction_id: '12345')
      }.to raise_error(ArgumentError)
    end

    it 'initiates a recurrent transaction for payment method visa' do
      response = gateway.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: '12345', transaction_id: '12345')
      expect(response).to be_an_instance_of(Buckaruby::RecurrentTransactionResponse)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT_RECURRENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::VISA)
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end
  end

  describe '#refundable_transaction?' do
    it 'raises an exception when required parameters are missing' do
      expect {
        gateway.refundable_transaction?
      }.to raise_error(ArgumentError)
    end

    it 'returns true when the transaction is refundable' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=RefundInfo').to_return(body: File.read('spec/fixtures/responses/refund_info_success.txt'))

      response = gateway.refundable_transaction?(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be true
    end

    it 'returns false when the transaction was not found' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=RefundInfo').to_return(body: File.read('spec/fixtures/responses/refund_info_error.txt'))

      response = gateway.refundable_transaction?(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be false
    end
  end

  describe '#refund_transaction' do
    it 'raises an exception when required parameters are missing' do
      expect {
        gateway.refund_transaction
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when the transaction is not refundable' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=RefundInfo').to_return(body: File.read('spec/fixtures/responses/refund_info_error.txt'))

      expect {
        gateway.refund_transaction(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      }.to raise_error(Buckaruby::NonRefundableTransactionException)
    end

    it 'refunds the transaction' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=RefundInfo').to_return(body: File.read('spec/fixtures/responses/refund_info_success.txt'))
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequest').to_return(body: File.read('spec/fixtures/responses/refund_transaction_success.txt'))

      response = gateway.refund_transaction(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be_an_instance_of(Buckaruby::RefundTransactionResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq('8CCE4BB06339F28A506E1A328025D7DF13CCAD59')
      expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
      expect(response.refunded_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end
  end

  describe '#status' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_success.txt'))
    end

    it 'raises an exception when required parameters are missing' do
      expect {
        gateway.status
      }.to raise_error(ArgumentError)
    end

    it 'returns the transaction status' do
      response = gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be_an_instance_of(Buckaruby::StatusResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'includes consumer iban, bic and name for an ideal response' do
      response = gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.consumer_iban).to eq('NL44RABO0123456789')
      expect(response.consumer_bic).to eq('RABONL2U')
      expect(response.consumer_name).to eq('J. de Tester')
    end

    it 'returns the transaction status for a refund' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_refund_success.txt'))

      response = gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be_an_instance_of(Buckaruby::StatusResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq('8CCE4BB06339F28A506E1A328025D7DF13CCAD59')
      expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
      expect(response.refunded_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'raises an ApiException when API result Fail is returned' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: 'BRQ_APIRESULT=Fail&BRQ_APIERRORMESSAGE=Invalid+request')

      expect {
        gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      }.to raise_error(Buckaruby::ApiException)
    end

    it 'raises a SignatureException when the signature is missing' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: 'BRQ_APIRESULT=Success')

      expect {
        gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      }.to raise_error(Buckaruby::SignatureException, "Sent signature () doesn't match generated signature (48e5a16f76a6a4ad6c3fb9685c0f40d0c2c475d6)")
    end

    it 'raises a SignatureException when the signature is invalid' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: 'BRQ_APIRESULT=Success&BRQ_SIGNATURE=abcdefgh1234567890abcdefgh1234567890')

      expect {
        gateway.status(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      }.to raise_error(Buckaruby::SignatureException, "Sent signature (abcdefgh1234567890abcdefgh1234567890) doesn't match generated signature (48e5a16f76a6a4ad6c3fb9685c0f40d0c2c475d6)")
    end
  end

  describe '#cancellable_transaction?' do
    it 'raises an exception when required parameters are missing' do
      expect {
        gateway.cancellable_transaction?
      }.to raise_error(ArgumentError)
    end

    it 'returns true when the transaction is cancellable' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_cancellable.txt'))

      response = gateway.cancellable_transaction?(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be true
    end

    it 'returns false when the transaction is not cancellable' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_noncancellable.txt'))

      response = gateway.cancellable_transaction?(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be false
    end
  end

  describe '#cancel_transaction' do
    it 'raises an exception when required parameters are missing' do
      expect {
        gateway.cancel_transaction
      }.to raise_error(ArgumentError)
    end

    it 'raises a NonCancellableTransactionException when the transaction is not cancellable' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_noncancellable.txt'))

      expect {
        gateway.cancel_transaction(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      }.to raise_error(Buckaruby::NonCancellableTransactionException)
    end

    it 'cancels the transaction' do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionStatus').to_return(body: File.read('spec/fixtures/responses/status_cancellable.txt'))
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=CancelTransaction').to_return(body: File.read('spec/fixtures/responses/cancel_success.txt'))

      response = gateway.cancel_transaction(transaction_id: '41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response).to be_an_instance_of(Buckaruby::CancelResponse)
    end
  end

  describe '#specify_transaction' do
    before do
      stub_request(:post, 'https://checkout.buckaroo.nl/nvp/?op=TransactionRequestSpecification').to_return(body: File.read('spec/fixtures/responses/specify_transaction_success.txt'))
    end

    it 'retrieves the specification for setting up a transaction' do
      response = gateway.specify_transaction
      expect(response).to be_an_instance_of(Buckaruby::TransactionSpecificationResponse)

      services = response.services
      expect(services).to be_an_instance_of(Array)
      expect(services.length).to eq(2)

      service = services.last
      expect(service).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(service[:name]).to eq(Buckaruby::PaymentMethod::VISA)
      expect(service[:description]).to eq('Visa')
      expect(service[:version]).to eq('1')

      currencies = service[:supportedcurrencies]
      expect(currencies).to be_an_instance_of(Array)
      expect(currencies.length).to eq(21)

      currency = currencies.last
      expect(currency).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(currency[:name]).to eq('US Dollar')
      expect(currency[:code]).to eq(Buckaruby::Currency::US_DOLLAR)
    end
  end

  describe '#parse_push' do
    it 'raises an exception when parameter is nil' do
      expect {
        gateway.parse_push(nil)
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when parameter is an empty Hash' do
      expect {
        gateway.parse_push({})
      }.to raise_error(ArgumentError)
    end

    it 'raises an exception when parameter is an empty String' do
      expect {
        gateway.parse_push('')
      }.to raise_error(ArgumentError)
    end

    it 'raises a SignatureException when the signature is invalid' do
      params = File.read('spec/fixtures/responses/push_invalid_signature.txt')

      expect {
        gateway.parse_push(params)
      }.to raise_error(Buckaruby::SignatureException, "Sent signature (abcdefgh1234567890abcdefgh1234567890) doesn't match generated signature (0a74bba15fccd8094f33678c001b44851643876d)")
    end

    it 'returns the status when the signature is valid' do
      params = File.read('spec/fixtures/responses/push_valid_signature.txt')

      response = gateway.parse_push(params)
      expect(response).to be_an_instance_of(Buckaruby::PushResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    it 'accepts a Hash as parameters' do
      params = { 'brq_amount' => '10.00', 'brq_currency' => 'EUR', 'brq_customer_name' => 'J. de Tester', 'brq_description' => 'Test', 'brq_invoicenumber' => '12345', 'brq_mutationtype' => 'Collecting', 'brq_payer_hash' => 'e02377112efcd30bb7420bb1b9855a3778864572', 'brq_payment' => 'E86256B2787EE7FF0C33D0D4C6159CD922227B79', 'brq_service_ideal_consumerbic' => 'RABONL2U', 'brq_service_ideal_consumeriban' => 'NL44RABO0123456789', 'brq_service_ideal_consumerissuer' => 'Rabobank', 'brq_service_ideal_consumername' => 'J. de Tester', 'brq_statuscode' => '190', 'brq_statuscode_detail' => 'S001', 'brq_statusmessage' => 'Transaction successfully processed', 'brq_test' => 'true', 'brq_timestamp' => '2014-11-05 13:10:42', 'brq_transaction_method' => 'ideal', 'brq_transaction_type' => 'C021', 'brq_transactions' => '41C48B55FA9164E123CC73B1157459E840BE5D24', 'brq_websitekey' => '12345678', 'brq_signature' => '0a74bba15fccd8094f33678c001b44851643876d' }

      response = gateway.parse_push(params)
      expect(response).to be_an_instance_of(Buckaruby::PushResponse)
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
      expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
      expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
      expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
      expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
      expect(response.invoicenumber).to eq('12345')
      expect(response.timestamp).to be_an_instance_of(Time)
    end

    context 'when push is a payment response' do
      it 'sets the success status when payment status is success' do
        params = File.read('spec/fixtures/responses/push_payment_success.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the failed status when payment status is failed' do
        params = File.read('spec/fixtures/responses/push_payment_failed.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::FAILED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the rejected status when payment status is rejected' do
        params = File.read('spec/fixtures/responses/push_payment_rejected.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::REJECTED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the cancelled status when payment status is cancelled' do
        params = File.read('spec/fixtures/responses/push_payment_cancelled.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::CANCELLED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the pending status when payment status is pending' do
        params = File.read('spec/fixtures/responses/push_payment_pending.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'includes account iban, bic and name for an ideal response' do
        params = File.read('spec/fixtures/responses/push_payment_success.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.consumer_iban).to eq('NL44RABO0123456789')
        expect(response.consumer_bic).to eq('RABONL2U')
        expect(response.consumer_name).to eq('J. de Tester')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'includes account iban, name, mandate reference and collect date for a sepa direct debit response' do
        params = File.read('spec/fixtures/responses/push_payment_sepa.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.consumer_iban).to eq('NL13TEST0123456789')
        expect(response.consumer_name).to eq('J. Tester')
        expect(response.mandate_reference).to eq('012345')
        expect(response.collect_date).to eq(Date.new(2014, 11, 13))
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'returns transaction type payment when cancelling a visa or mastercard transaction (empty transaction type)' do
        params = File.read('spec/fixtures/responses/push_payment_empty_transaction_type.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::CANCELLED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the transaction type to payment and payment method to VISA for visa push' do
        params = File.read('spec/fixtures/responses/push_payment_visa.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::VISA)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the transaction type to payment and payment method to American Express for amex push' do
        params = File.read('spec/fixtures/responses/push_payment_amex.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::AMERICAN_EXPRESS)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the transaction type to payment and payment method to Sofort for sofort push' do
        params = File.read('spec/fixtures/responses/push_payment_sofort.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SOFORT)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'sets the transaction type to payment and payment method to Giropay for giropay push' do
        params = File.read('spec/fixtures/responses/push_payment_giropay.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::GIROPAY)
        expect(response.transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end
    end

    context 'when push is a payment recurrent response' do
      it 'recognizes a visa payment recurrent response' do
        params = File.read('spec/fixtures/responses/push_recurrent_visa.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT_RECURRENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::VISA)
        expect(response.transaction_id).to eq('B51118F58785274E117EFE1BF99D4D50CCB96949')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'recognizes a sepa direct debit payment recurrent response' do
        params = File.read('spec/fixtures/responses/push_recurrent_sepa.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT_RECURRENT)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq('B51118F58785274E117EFE1BF99D4D50CCB96949')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end
    end

    context 'when push is a refund response' do
      it 'recognizes an ideal refund response' do
        params = File.read('spec/fixtures/responses/push_refund_ideal.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::IDEAL)
        expect(response.transaction_id).to eq('B51118F58785274E117EFE1BF99D4D50CCB96949')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.refunded_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'recognizes a paypal refund response' do
        params = File.read('spec/fixtures/responses/push_refund_paypal.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::PAYPAL)
        expect(response.transaction_id).to eq('B51118F58785274E117EFE1BF99D4D50CCB96949')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.refunded_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'recognizes an amex refund response' do
        params = File.read('spec/fixtures/responses/push_refund_amex.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REFUND)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::AMERICAN_EXPRESS)
        expect(response.transaction_id).to eq('B51118F58785274E117EFE1BF99D4D50CCB96949')
        expect(response.payment_id).to be_nil
        expect(response.refunded_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end
    end

    context 'when push is a reversal response' do
      it 'recognizes a sepa direct debit reversal response' do
        params = File.read('spec/fixtures/responses/push_reversal_sepa.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REVERSAL)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT)
        expect(response.transaction_id).to eq('8CCE4BB06339F28A506E1A328025D7DF13CCAD59')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.reversed_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end

      it 'recognizes a paypal reversal response' do
        params = File.read('spec/fixtures/responses/push_reversal_paypal.txt')

        response = gateway.parse_push(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::SUCCESS)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::REVERSAL)
        expect(response.payment_method).to eq(Buckaruby::PaymentMethod::PAYPAL)
        expect(response.transaction_id).to eq('8CCE4BB06339F28A506E1A328025D7DF13CCAD59')
        expect(response.payment_id).to eq('E86256B2787EE7FF0C33D0D4C6159CD922227B79')
        expect(response.reversed_transaction_id).to eq('41C48B55FA9164E123CC73B1157459E840BE5D24')
        expect(response.invoicenumber).to eq('12345')
        expect(response.timestamp).to be_an_instance_of(Time)
      end
    end
  end
end
