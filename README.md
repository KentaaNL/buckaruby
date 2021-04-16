# Buckaruby

[![Gem Version](https://badge.fury.io/rb/buckaruby.svg)](https://badge.fury.io/rb/buckaruby)
[![Build Status](https://travis-ci.org/KentaaNL/buckaruby.svg?branch=master)](https://travis-ci.org/KentaaNL/buckaruby)
[![Code Climate](https://codeclimate.com/github/KentaaNL/buckaruby/badges/gpa.svg)](https://codeclimate.com/github/KentaaNL/buckaruby)

The Buckaruby gem provides a Ruby library for communicating with the Buckaroo Payment Engine 3.0.

## Installation

Add this line to your application's Gemfile:

    gem 'buckaruby'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install buckaruby

## Usage

Configure Buckaruby to use it in test or production (live) mode:

```ruby
Buckaruby::Gateway.mode = :production  # defaults to :test
```

### Initialization

Create the gateway and configure it using your Buckaroo website key and secret key:

```ruby
gateway = Buckaruby::Gateway.new(
  website: "123456789",       # website key
  secret: "abcdef1234567890"  # secret key for digital signing
)
```

As hashing method for the digital signature, Buckaruby uses SHA-1 by default. You can change this to SHA-256 or SHA-512 by setting the parameter `hash_method` when creating the gateway:

```ruby
gateway = Buckaruby::Gateway.new(
  website: "123456789",
  secret: "abcdef1234567890",
  hash_method: :sha512        # hash method for the digital signature (:sha1, :sha256 or :sha512)
)
```

You can override the default mode with the parameter `mode`.

### Payment methods

To retrieve the payment methods enabled in Buckaroo and supported by this library, you can use the method `payment_methods`. This method will return an array with all payment methods that can be used. See also `Buckaruby::PaymentMethod` for predefined constants.

```ruby
payment_methods = gateway.payment_methods
```

### Start transaction

To start a new transaction, use the method `setup_transaction`:

```ruby
options = {
  amount: 10,
  payment_method: Buckaruby::PaymentMethod::IDEAL,
  payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first,
  invoicenumber: "12345",
  return_url: "http://www.return.url/"
}

response = gateway.setup_transaction(options)
```

The response includes a `status` to check if the transaction was successful and a `redirect_url` which you can use to redirect the user to when present.

See `Buckaruby::SetupTransactionResponse` for more details.

### Recurrent transaction

Recurrent transactions are supported for all credit cards, PayPal and SEPA Direct Debit.

You first need to execute a normal transaction, with the parameter `recurring` set to true.

```ruby
options = {
  amount: 10,
  payment_method: Buckaruby::PaymentMethod::PAYPAL,
  invoicenumber: "12345",
  return_url: "http://www.return.url/",
  recurring: true
}

response = gateway.setup_transaction(options)

transaction = response.transaction_id  # use this for the recurrent transaction
```

The response will include a `transaction_id` which you must use to make a recurrent transaction:

```ruby
options = {
  amount: 10,
  payment_method: Buckaruby::PaymentMethod::PAYPAL,
  invoicenumber: "12345",
  transaction_id: "abcdefg"
}

response = gateway.recurrent_transaction(options)
```

The response includes a `status` to check if the transaction was successful.

See `Buckaruby::RecurrentTransactionResponse` for more details.

### Refund transaction

For some transactions it's possible to do a refund: Buckaroo creates a new "reverse" transaction based on the original transaction.

First check if the transaction is refundable, with the parameter `transaction_id` set to the original transaction ID:

```ruby
response = gateway.refundable?(transaction_id: "abcdefg")
```

If the reponse is positive then you can refund the transaction with:

```ruby
response = gateway.refund_transaction(transaction_id: "abcdefg")
```

The response includes a `status` to check if the refund was successful.

If you try to refund a transaction that's not refundable, then a `Buckaruby::NonRefundableTransactionException` will be raised.

See `Buckaruby::RefundTransactionResponse` for more details.

### Cancel transaction

Sometimes a transaction can be cancelled, for example a SEPA Direct Debit transaction before it has been offered to the bank.

You can check if the transaction is cancellable, by using the method `cancellable?` with the parameter `transaction_id`:

```ruby
response = gateway.cancellable?(transaction_id: "abcdefg")
```

If the response is positive then you can cancel the transaction with:

```ruby
response = gateway.cancel_transaction(transaction_id: "abcdefg")
```

If this does not result in an exception, then the cancel was successful.

If you try to cancel a transaction that's not cancellable, then a `Buckaruby::NonCancellableTransactionException` will be raised.

### Push response

Buckaroo can be configured to send push notifications for transactions. You can use the method `callback` to verify and parse the push response:

```ruby
response = gateway.callback(params)
```

See `Buckaruby::CallbackResponse` for more details.

### Get status

To query the status of any transaction, use the method `status` with either the parameter `transaction_id` or `payment_id`:

```ruby
response = gateway.status(transaction_id: 12345)
```

See `Buckaruby::StatusResponse` for more details.

### Generate

TODO: describe generate / iDEAL QR

```
response = gateway.generate(service: Buckaruby::Service::IDEAL_QR, description: "Kentaa", amount: "12.50", purchase_id: "12345", expires_at: Date.today + 30, image_size: 250)
```

See `Buckaruby::DataResponse` for more details.

### Merchant variables

You can send custom variables and additional variables with each request.

Use the parameter `custom` to build a hash with custom variables and `additional` for building a hash with additional variabeles.
For example:

```ruby
options = {
  amount: 10,
  payment_method: Buckaruby::PaymentMethod::IDEAL,
  payment_issuer: Buckaruby::Ideal::ISSUERS.keys.first,
  invoicenumber: "12345",
  return_url: "http://www.return.url/",
  custom: {
    foo: "bar",
    quux: "42"
  },
  additional: {
    myreference: "12345"
  }
}

response = gateway.setup_transaction(options)
```

In the response, you can retrieve the custom and additional variables with the methods `custom` and `additional`:

```ruby
puts response.custom[:foo]
puts response.additional[:myreference]
````

### Transaction request specification

To retrieve a specification about what needs to be sent with transaction request, you can use the method `specify_transaction`. The parameter `payment_method` is optional. When supplied it will only send the specification for that payment method.

This request is also used by the `payment_methods` method to determine which services (payment methods) are enabled in Buckaroo.

```ruby
response = gateway.specify_transaction(payment_method: Buckaruby::PaymentMethod::IDEAL)
```

See `Buckaruby::TransactionSpecificationResponse` for more details.

### Error handling

When missing or invalid parameters are passed to any method, an `ArgumentError` will be raised.

When a request to Buckaroo fails because of connection problems, a `Buckaruby::ConnectionException` will be raised.

When Buckaroo returns an invalid response (status code is not 2xx), a `Buckaruby::InvalidResponseException` will be raised.

When an API call to Buckaroo results in a "Fail" returned, a `Buckaruby::ApiException` will be raised.

When the signature could not be verified, a `Buckaruby::SignatureException` will be raised.

All Buckaruby exceptions listed here inherit from the class `Buckaruby::BuckarooException`.

## Example

For a complete and working example project check out [Buckaruby PoC](https://github.com/KentaaNL/buckaruby-poc).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/KentaaNL/buckaruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
