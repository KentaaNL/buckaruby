require 'spec_helper'

describe Buckaruby::Gateway do
  describe 'initialization' do
    describe 'bad parameters' do
      it 'should raise an exception when creating a new instance with invalid parameters' do
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

    describe 'set mode' do
      it 'should be test when no mode is passed' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D")
        expect(gateway.options[:mode]).to eq(:test)
      end

      it 'should be test when mode test is passed' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :test)
        expect(gateway.options[:mode]).to eq(:test)
      end

      it 'should be production when mode production is passed' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :production)
        expect(gateway.options[:mode]).to eq(:production)
      end

      it 'should raise an exception when an invalid mode is passed' do
        expect {
          Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :invalid)
        }.to raise_error(ArgumentError)
      end
    end

    describe 'set hash method' do
      it 'should raise an exception when an invalid hash method is passed' do
        expect {
          Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :invalid)
        }.to raise_error(ArgumentError)
      end

      it 'should accept SHA-1 as hash method' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: 'SHA1')
        expect(gateway.options[:hash_method]).to eq(:sha1)
      end

      it 'should accept SHA-256 as hash method' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :SHA256)
        expect(gateway.options[:hash_method]).to eq(:sha256)
      end

      it 'should accept SHA-512 as hash method' do
        gateway = Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :sha512)
        expect(gateway.options[:hash_method]).to eq(:sha512)
      end
    end
  end

  subject { Buckaruby::Gateway.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D") }

  it { expect(subject).to be_an_instance_of(Buckaruby::Gateway) }

  describe 'get issuers' do
    context 'when no or false parameters are passed' do
      it 'should raise an ArgumentError' do
        expect { subject.issuers }.to raise_error(ArgumentError)
        expect { subject.issuers(:wrong) }.to raise_error(ArgumentError)
      end
    end

    context 'when ideal is passed' do
      let(:issuers) { subject.issuers(Buckaruby::PaymentMethod::IDEAL) }
      it { expect(issuers.length).to be > 0 }
      it { expect(issuers).to include("INGBNL2A" => "ING") }
    end

    context 'when visa, mastercard, sepa direct debit, paypal or is passed' do
      it 'should raise an ArgumentError' do
        expect { subject.issuers(Buckaruby::PaymentMethod::VISA) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::MASTER_CARD) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT) }.to raise_error(ArgumentError)
        expect { subject.issuers(Buckaruby::PaymentMethod::PAYPAL) }.to raise_error(ArgumentError)
      end
    end
  end

  describe 'initiate transaction' do
    before(:each) do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
        .to_return(body: "BRQ_ACTIONREQUIRED=redirect&BRQ_AMOUNT=10.00&BRQ_APIRESULT=ActionRequired&BRQ_CURRENCY=EUR&BRQ_DESCRIPTION=Test&BRQ_INVOICENUMBER=12345&BRQ_PAYMENT=12345&BRQ_PAYMENT_METHOD=ideal&BRQ_REDIRECTURL=https%3A%2F%2Ftestcheckout.buckaroo.nl%2Fhtml%2Fredirect.ashx%3Fr%3D41C48B55FA9164E123CC73B1157459E840BE5D24&BRQ_SERVICE_IDEAL_CONSUMERISSUER=Rabobank&BRQ_STATUSCODE=791&BRQ_STATUSCODE_DETAIL=S002&BRQ_STATUSMESSAGE=An+additional+action+is+required%3A+RedirectToIdeal&BRQ_TEST=true&BRQ_TIMESTAMP=2014-11-05+13%3A10%3A40&BRQ_TRANSACTIONS=41C48B55FA9164E123CC73B1157459E840BE5D24&BRQ_WEBSITEKEY=12345678&BRQ_SIGNATURE=3d6ef7e249d9509d120c7b84f27f081adf06074b")
    end

    it 'should raise an exception when initiating a transaction with missing parameters' do
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

    it 'should raise an exception when initiating a transaction with invalid amount' do
      expect {
        subject.setup_transaction(amount: 0, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)

      expect {
        subject.setup_transaction(amount: -1, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'should raise an exception when initiating a transaction with invalid payment method' do
      expect {
        subject.setup_transaction(amount: 10, payment_method: "abc", payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'should raise an exception when initiating a transaction with invalid payment issuer' do
      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: "abc", invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(ArgumentError)
    end

    it 'should raise a ConnectionException when connection the Buckaroo fails' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
        .to_raise(Errno::ECONNREFUSED)

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(Buckaruby::ConnectionException)
    end

    it 'should raise an ApiException when API result Fail is returned' do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
        .to_return(body: "BRQ_APIRESULT=Fail&BRQ_APIERRORMESSAGE=Invalid+request")

      expect {
        subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      }.to raise_error(Buckaruby::ApiException)
    end

    describe 'should initiate a transaction when amount is integer, decimal or string' do
      context 'when amount is an integer' do
        let(:response) { subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }
        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).to be }
      end

      context 'when amount is a decimal' do
        let(:response) { subject.setup_transaction(amount: 10.50, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }
        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).to be }
      end

      context 'when amount is a string' do
        let(:response) { subject.setup_transaction(amount: '10', payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/") }
        it { expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse) }
        it { expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24") }
        it { expect(response.redirect_url).to be }
      end
    end

    it 'should initiate a transaction for payment method ideal' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).to be
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'should initiate a transaction for payment method visa' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::VISA, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).to be
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'should initiate a transaction for payment method mastercard' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::MASTER_CARD, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).to be
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'should initiate a transaction for payment method sepa direct debit' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::SEPA_DIRECT_DEBIT, invoicenumber: "12345", return_url: "http://www.return.url/", account_iban: "NL13TEST0123456789", account_name: "J. Tester", mandate_reference: "00P12345", collect_date: Date.new(2016, 1, 1))
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    it 'should initiate a transaction for payment method paypal' do
      response = subject.setup_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::PAYPAL, invoicenumber: "12345", return_url: "http://www.return.url/")
      expect(response).to be_an_instance_of(Buckaruby::SetupTransactionResponse)
      expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::PENDING)
      expect(response.redirect_url).to be
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end
  end

  describe 'initiate recurrent transaction' do
    before(:each) do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionRequest")
        .to_return(body:
"BRQ_AMOUNT=10.00&BRQ_APIRESULT=Success&BRQ_CURRENCY=EUR&BRQ_CUSTOMER_NAME=Test&BRQ_DESCRIPTION=Test&BRQ_INVOICENUMBER=12345&BRQ_ISSUING_COUNTRY=IE&BRQ_PAYMENT=8EE820309AA9455C91350DD5D3160362&BRQ_PAYMENT_METHOD=visa&BRQ_RECURRING=True&BRQ_SERVICE_VISA_CARDEXPIRATIONDATE=2016-01&BRQ_SERVICE_VISA_CARDNUMBERENDING=0969&BRQ_SERVICE_VISA_MASKEDCARDNUMBER=491611%2A%2A%2A%2A%2A%2A0969&BRQ_STATUSCODE=190&BRQ_STATUSCODE_DETAIL=S001&BRQ_STATUSMESSAGE=Transaction+successfully+processed&BRQ_TEST=true&BRQ_TIMESTAMP=2016-01-19+15%3A13%3A44&BRQ_TRANSACTIONS=41C48B55FA9164E123CC73B1157459E840BE5D24&BRQ_WEBSITEKEY=12345678&BRQ_SIGNATURE=b6a5a54c7e0d731f211c2080519e7aabc9775f47")
    end

    it 'should raise an exception when initiating a recurrent transaction with missing parameters' do
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

    it 'should raise an exception when initiating a transaction with invalid payment method' do
      expect {
        subject.recurrent_transaction(amount: 10, payment_method: Buckaruby::PaymentMethod::IDEAL, invoicenumber: "12345", transaction_id: "12345")
      }.to raise_error(ArgumentError)
    end

    it 'should initiate a recurrent transaction for payment method visa' do
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

  describe 'get transaction status' do
    before(:each) do
      stub_request(:post, "https://testcheckout.buckaroo.nl/nvp/?op=TransactionStatus")
        .to_return(body:
"BRQ_AMOUNT=10.00&BRQ_APIRESULT=Success&BRQ_CURRENCY=EUR&BRQ_CUSTOMER_NAME=J.+de+Tester&BRQ_DESCRIPTION=Test&BRQ_INVOICENUMBER=12345&BRQ_MUTATIONTYPE=Collecting&BRQ_PAYER_HASH=e02377112efcd30bb7420bb1b9855a3778864572&BRQ_PAYMENT=E86256B2787EE7FF0C33D0D4C6159CD922227B79&BRQ_SERVICE_IDEAL_CONSUMERBIC=RABONL2U&BRQ_SERVICE_IDEAL_CONSUMERIBAN=NL44RABO0123456789&BRQ_SERVICE_IDEAL_CONSUMERISSUER=ING&BRQ_SERVICE_IDEAL_CONSUMERNAME=J.+de+Tester&BRQ_STATUSCODE=190&BRQ_STATUSCODE_DETAIL=S001&BRQ_STATUSMESSAGE=Transaction+successfully+processed&BRQ_TEST=true&BRQ_TIMESTAMP=2015-02-16+13%3A25%3A58&BRQ_TRANSACTION_CANCELABLE=False&BRQ_TRANSACTION_METHOD=ideal&BRQ_TRANSACTION_TYPE=C021&BRQ_TRANSACTIONS=41C48B55FA9164E123CC73B1157459E840BE5D24&BRQ_WEBSITEKEY=12345678&BRQ_SIGNATURE=b92de342cc863acd0c46ed3c8cb6add87668e22f")
    end

    it 'should raise an exception when initiating a transaction with missing parameters' do
      expect {
        subject.status
      }.to raise_error(ArgumentError)
    end

    it { expect(subject.status(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")).to be_an_instance_of(Buckaruby::StatusResponse) }

    it 'should return transaction status' do
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

    it 'should include account iban, bic and name for an ideal response' do
      response = subject.status(transaction_id: "41C48B55FA9164E123CC73B1157459E840BE5D24")
      expect(response.account_iban).to eq("NL44RABO0123456789")
      expect(response.account_bic).to eq("RABONL2U")
      expect(response.account_name).to eq("J. de Tester")
    end
  end

  describe 'verifying payment response' do
    it 'should raise an exception when parameters are invalid' do
      expect {
        subject.callback
      }.to raise_error(ArgumentError)
    end

    it 'should raise a SignatureException when the signature is invalid' do
      params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "abcdefgh1234567890abcdefgh1234567890" }

      expect {
        subject.callback(params)
      }.to raise_error(Buckaruby::SignatureException)
    end

    it 'should return the status when the signature is valid' do
      params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "0a74bba15fccd8094f33678c001b44851643876d" }

      response = subject.callback(params)
      expect(response).to be_an_instance_of(Buckaruby::CallbackResponse)
      expect(response.transaction_status).to be
      expect(response.transaction_type).to be
      expect(response.payment_method).to be
      expect(response.payment_id).to be
      expect(response.invoicenumber).to be
      expect(response.timestamp).to be_an_instance_of(Time)
      expect(response.to_h).to be_an_instance_of(Hash)
    end

    context 'payment response' do
      it 'should set the success status when payment status is success' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "0a74bba15fccd8094f33678c001b44851643876d" }

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

      it 'should set the failed status when payment status is failed' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "490", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "7e1957cea05cab55aa6e29c36182f9eed6a9984b" }

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

      it 'should set the rejected status when payment status is rejected' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "690", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "ec7b055655f95a23308ed30c085cd65dedccc197" }

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

      it 'should set the cancelled status when payment status is cancelled' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "890", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "71cc4d8a49e4062c6d394201f39f4b81b5a39026" }

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

      it 'should set the pending status when payment status is pending' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "790", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "3e166e22a7ab5880b7424d5614a7fb227d8a7770" }

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

      it 'should include account iban, bic and name for an ideal response' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payer_hash" => "e02377112efcd30bb7420bb1b9855a3778864572", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_ideal_consumerbic" => "RABONL2U", "brq_service_ideal_consumeriban" => "NL44RABO0123456789", "brq_service_ideal_consumerissuer" => "Rabobank", "brq_service_ideal_consumername" => "J. de Tester", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:10:42", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C021", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "0a74bba15fccd8094f33678c001b44851643876d" }

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

      it 'should include account iban, name, mandate reference and collect date for a sepa direct debit response' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. Tester", "brq_description" => "Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_service_sepadirectdebit_collectdate" => "2014-11-13", "brq_service_sepadirectdebit_customeriban" => "NL13TEST0123456789", "brq_service_sepadirectdebit_directdebittype" => "OneOff", "brq_service_sepadirectdebit_mandatedate" => "2014-11-05", "brq_service_sepadirectdebit_mandatereference" => "012345", "brq_statuscode" => "791", "brq_statuscode_detail" => "C620", "brq_statusmessage" => "Awaiting transfer to bank.", "brq_test" => "true", "brq_timestamp" => "2014-11-05 13:45:18", "brq_transaction_method" => "SepaDirectDebit", "brq_transaction_type" => "C004", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "bcb7924473707d3b7067eb566cd6956dcf354d4c" }

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

      it 'should return transaction type payment when cancelling a visa or mastercard transaction (empty transaction type)' do
        params = { "brq_amount" => "10.00", "brq_currency" => "EUR", "brq_description" => "Test cancel", "brq_invoicenumber" => "12345", "brq_mutationtype" => "NotSet", "brq_statuscode" => "890", "brq_statusmessage" => "Cancelled by user", "brq_test" => "false", "brq_timestamp" => "2015-01-27 10:26:42", "brq_transaction_type" => "", "brq_transactions" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_websitekey" => "12345678", "brq_signature" => "9bf412565dfd7399245975a132f649caa7d1d66f" }

        response = subject.callback(params)
        expect(response.transaction_status).to eq(Buckaruby::TransactionStatus::CANCELLED)
        expect(response.transaction_type).to eq(Buckaruby::TransactionType::PAYMENT)
        expect(response.transaction_id).to eq("41C48B55FA9164E123CC73B1157459E840BE5D24")
        expect(response.invoicenumber).to eq("12345")
        expect(response.timestamp).to be_an_instance_of(Time)
        expect(response.to_h).to be_an_instance_of(Hash)
      end
    end

    context 'payment recurrent response' do
      it 'should recognize a sepa direct debit payment recurrent response' do
        params = { "brq_amount" => "1.00", "brq_currency" => "EUR", "brq_customer_name" => "J. Tester", "brq_description" => "Recurrent: Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_recurring" => "True", "brq_SERVICE_sepadirectdebit_CollectDate" => "2016-09-16", "brq_SERVICE_sepadirectdebit_CustomerIBAN" => "NL13TEST0123456789", "brq_SERVICE_sepadirectdebit_DirectDebitType" => "First", "brq_SERVICE_sepadirectdebit_MandateDate" => "2016-09-07", "brq_SERVICE_sepadirectdebit_MandateReference" => "e1a31b3e461ab74cdbacf16bccd5290f9a284618", "brq_statuscode" => "190", "brq_statusmessage" => "Success", "brq_test" => "false", "brq_timestamp" => "2016-09-16 00:26:03", "brq_transaction_method" => "SepaDirectDebit", "brq_transaction_type" => "C005", "brq_transactions" => "B51118F58785274E117EFE1BF99D4D50CCB96949", "brq_websitekey" => "12345678", "brq_signature" => "851d0eacc314ceb9070abeb83d1853270459d81a" }

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

    context 'refund response' do
      it 'should recognize an ideal refund response' do
        params = { "brq_amount_credit" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. de Tester", "brq_description" => "Refund: Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_relatedtransaction_refund" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_service_ideal_customeraccountname" => "J. de Tester", "brq_service_ideal_customerbic" => "RABONL2U", "brq_service_ideal_customeriban" => "NL44RABO0123456789", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "true", "brq_timestamp" => "2014-11-06 15:27:31", "brq_transaction_method" => "ideal", "brq_transaction_type" => "C121", "brq_transactions" => "B51118F58785274E117EFE1BF99D4D50CCB96949", "brq_websitekey" => "12345678", "brq_signature" => "395bacf2bb5231501b94b3d22996f4f61c013f4b" }

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

      it 'should recognize a paypal refund response' do
        params = { "brq_amount_credit" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. Tester", "brq_description" => "Refund: Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Processing", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_relatedtransaction_refund" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_statuscode" => "190", "brq_statuscode_detail" => "S001", "brq_statusmessage" => "Transaction successfully processed", "brq_test" => "false", "brq_timestamp" => "2014-11-06 15:04:20", "brq_transaction_method" => "paypal", "brq_transaction_type" => "V110", "brq_transactions" => "B51118F58785274E117EFE1BF99D4D50CCB96949", "brq_websitekey" => "12345678", "brq_signature" => "da55998b9681cc9d10f983e21f44c0510b474c12" }

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
    end

    context 'reversal response' do
      it 'should recognize a sepa direct debit reversal response' do
        params = { "brq_amount_credit" => "10.00", "brq_currency" => "EUR", "brq_customer_name" => "J. Tester", "brq_description" => "Reversal: Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Collecting", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_relatedtransaction_reversal" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_service_sepadirectdebit_reasoncode" => "MD06", "brq_service_sepadirectdebit_reasonexplanation" => "Debtor uses 8 weeks reversal right", "brq_statuscode" => "190", "brq_statusmessage" => "Success", "brq_test" => "false", "brq_timestamp" => "2014-11-28 03:37:48", "brq_transaction_method" => "SepaDirectDebit", "brq_transaction_type" => "C501", "brq_transactions" => "8CCE4BB06339F28A506E1A328025D7DF13CCAD59", "brq_websitekey" => "12345678", "brq_signature" => "4b8ccf699dadca7465510ba94a59fa9d7b5b050a" }

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

      it 'should recognize a paypal reversal response' do
        params = { "brq_amount_credit" => "15.40", "brq_currency" => "EUR", "brq_customer_name" => "J. Tester", "brq_description" => "Reversal: Test", "brq_invoicenumber" => "12345", "brq_mutationtype" => "Processing", "brq_payment" => "E86256B2787EE7FF0C33D0D4C6159CD922227B79", "brq_relatedtransaction_reversal" => "41C48B55FA9164E123CC73B1157459E840BE5D24", "brq_statuscode" => "190", "brq_statusmessage" => "Success", "brq_test" => "false", "brq_timestamp" => "2015-12-12 08:26:46", "brq_transaction_method" => "paypal", "brq_transaction_type" => "V111", "brq_transactions" => "8CCE4BB06339F28A506E1A328025D7DF13CCAD59", "brq_websitekey" => "12345678", "brq_signature" => "124f1a2bdfbd952a8d909d45cce421b6734a2c41" }

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
