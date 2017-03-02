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

On success this will return a `Buckaruby::SetupTransactionResponse`.

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

On success this will return a `Buckaruby::RecurrentTransactionResponse`.

### Push response

Buckaroo can be configured to send push notifications for transactions. You can use the method `callback` to verify and parse the push response:

```ruby
response = gateway.callback(params)
```

On success this will return a `Buckaruby::CallbackResponse`.

### Get status

To query the status of any transaction, use the method `status` with either the parameter `transaction_id` or `payment_id`:

```ruby
response = gateway.status(transaction_id: 12345)
```

On success this will return a `Buckaruby::StatusResponse`.

### Error handling

When missing or invalid parameters are passed to any method, an `ArgumentError` will be raised.

When a request to Buckaroo fails because of connection problems, a `Buckaruby::ConnectionException` will be raised.

When Buckaroo returns an invalid response (status code is not 2xx), a `Buckaruby::InvalidResponseException` will be raised.

When an API call to Buckaroo results in a "Fail" returned, a `Buckaruby::ApiException` will be raised.

When the signature could not be verified, a `Buckaruby::SignatureException` will be raised.

All Buckaruby exceptions listed here inherit from the class `Buckaruby::BuckarooException`.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/KentaaNL/buckaruby.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
