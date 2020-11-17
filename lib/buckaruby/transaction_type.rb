# frozen_string_literal: true

module Buckaruby
  # Parses the transaction type from Buckaroo.
  module TransactionType
    PAYMENT = 1
    PAYMENT_RECURRENT = 2
    REFUND = 3
    REVERSAL = 4

    module_function

    # See https://support.buckaroo.nl/categorie%C3%ABn/integratie/transactietypes-overzicht
    def parse(brq_transaction_type, brq_recurring)
      if brq_transaction_type && !brq_transaction_type.empty?
        case brq_transaction_type
        when 'C021', 'V021',                                  # iDEAL
             'C002', 'C004', 'C005',                          # (SEPA) Direct Debit
             'V010', 'V014',                                  # PayPal
             'C090', 'V090',                                  # Bancontact
             'N074', 'C075',                                  # Sofort
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
          if brq_recurring && brq_recurring.casecmp("true").zero?
            TransactionType::PAYMENT_RECURRENT
          else
            TransactionType::PAYMENT
          end
        when 'C121',                                          # iDEAL
             'C102', 'C500',                                  # (SEPA) Direct Debit
             'V110',                                          # PayPal
             'C092', 'V092',                                  # Bancontact
             'N540', 'C543',                                  # Sofort
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
             'C544',                                          # Sofort

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
        # Fallback when transaction type is not known (e.g. cancelling credit card)
        TransactionType::PAYMENT
      end
    end
  end
end
