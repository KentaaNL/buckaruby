# Buckaruby changelog

## 1.4.0 (2020-04-06)

- Add `payment_methods` to retrieve all payment methods enabled by Buckaroo and supported by this library.
- Add `specify_transaction` to get a specification for setting up a transaction.
- Fix calcuating the signature for long responses and indexed fields.

## 1.3.1 (2019-12-04)

- Update list of credit card transaction types.

## 1.3.0 (2019-10-08)

- Add payment method American Express.

## 1.2.0 (2019-08-06)

- Add support for sending custom & additional variables with the request.

## 1.1.1 (2018-11-30)

- Add Handelsbanken to the list of iDEAL issuers.

## 1.1.0 (2018-06-01)

- Add payment method iDEAL processing.
- Add Moneyou to the list of iDEAL issuers.
- Implement refund transaction.
- Implement cancel transaction.

## 1.0.2 (2017-08-25)

- Recognize credit card transactions via Atos.
- Fix detection of recurrent payments.
- Minor improvements to exception handling.

## 1.0.1 (2017-01-05)

- Recognize status codes 792 & 793 as a pending transaction.
- For SEPA Direct Debit, make the collect date configurable and let Buckaroo determine the default.

## 1.0.0 (2016-11-24)

- First public release.
