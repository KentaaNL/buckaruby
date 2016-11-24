require 'spec_helper'

describe Buckaruby::Iban do
  describe 'calculate_iban' do
    describe 'bad initialization' do
      it 'should raise an exception when account number is not supplied' do
        expect {
          Buckaruby::Iban.calculate_iban(nil, 'INGB')
        }.to raise_error(ArgumentError)
      end

      it 'should raise an exception when account number is empty' do
        expect {
          Buckaruby::Iban.calculate_iban('', 'INGB')
        }.to raise_error(ArgumentError)
      end

      it 'should raise an exception when bank code is not supplied' do
        expect {
          Buckaruby::Iban.calculate_iban('555', nil)
        }.to raise_error(ArgumentError)
      end

      it 'should raise an exception when bank code is empty' do
        expect {
          Buckaruby::Iban.calculate_iban('555', '')
        }.to raise_error(ArgumentError)
      end

      it 'should raise an exception when country code is not supplied' do
        expect {
          Buckaruby::Iban.calculate_iban('555', 'INGB', '')
        }.to raise_error(ArgumentError)
      end

      it 'should raise an exception when country code is invalid' do
        expect {
          Buckaruby::Iban.calculate_iban('555', 'INGB', 'TEST')
        }.to raise_error(ArgumentError)
      end
    end

    it 'should calculate an IBAN for account number 1234 with ING bank' do
      iban = Buckaruby::Iban.calculate_iban('1234', 'INGB')
      expect(iban).to eq('NL08INGB0000001234')
    end

    it 'should calculate an IBAN for account number 1234567 with ING bank' do
      iban = Buckaruby::Iban.calculate_iban('1234567', 'INGB')
      expect(iban).to eq('NL20INGB0001234567')
    end

    it 'should calculate an IBAN for account number 55505 with ING bank' do
      iban = Buckaruby::Iban.calculate_iban('55505', 'INGB')
      expect(iban).to eq('NL70INGB0000055505')
    end

    it 'should calculate an IBAN for account number 395222419 with Rabobank' do
      iban = Buckaruby::Iban.calculate_iban('395222419', 'RABO')
      expect(iban).to eq('NL25RABO0395222419')
    end

    it 'should calculate an IBAN for account number 707070406 with ABN Amro' do
      iban = Buckaruby::Iban.calculate_iban('707070406', 'ABNA')
      expect(iban).to eq('NL87ABNA0707070406')
    end

    it 'should calculate an IBAN for account number 254668844 with Triodos bank' do
      iban = Buckaruby::Iban.calculate_iban('254668844', 'TRIO')
      expect(iban).to eq('NL56TRIO0254668844')
    end
  end
end
