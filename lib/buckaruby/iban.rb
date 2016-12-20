module Buckaruby
  # Helper for calculating the IBAN for a given account number, bank code and country code.
  class Iban
    def self.calculate_iban(account_number, bank_code, country_code = "NL")
      if account_number.nil? || account_number.to_s.empty?
        raise ArgumentError, "Invalid account number"
      end

      if bank_code.nil? || bank_code.to_s.empty?
        raise ArgumentError, "Invalid bank code"
      end

      if country_code.nil? || !country_code.match(/^[A-Z]{2}$/)
        raise ArgumentError, "Invalid or unknown country code"
      end

      account_identification = bank_code + account_number.rjust(10, '0')
      country_code_added = account_identification + country_code
      all_numbers = country_code_added.gsub(/[A-Z]/) { |p| (p.respond_to?(:ord) ? p.ord : p[0]) - 55 } + '00'
      verification_number = (98 - (all_numbers.to_i % 97)).to_s.rjust(2, '0')

      country_code + verification_number + account_identification
    end
  end
end
