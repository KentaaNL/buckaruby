# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Amount do
  describe '#positive?' do
    it 'returns true when amount is greater than zero' do
      expect(Buckaruby::Amount.new(1).positive?).to be true
      expect(Buckaruby::Amount.new('1').positive?).to be true
      expect(Buckaruby::Amount.new('1.23').positive?).to be true
    end

    it 'returns false when amount is equals zero' do
      expect(Buckaruby::Amount.new(0).positive?).to be false
      expect(Buckaruby::Amount.new('0').positive?).to be false
      expect(Buckaruby::Amount.new('0.00').positive?).to be false
    end

    it 'returns false when amount is is negative' do
      expect(Buckaruby::Amount.new(-1).positive?).to be false
      expect(Buckaruby::Amount.new('-1').positive?).to be false
      expect(Buckaruby::Amount.new('-1.23').positive?).to be false
    end
  end

  describe '#to_d' do
    it 'returns the decimal value of an Integer' do
      expect(Buckaruby::Amount.new(42).to_d).to eq(BigDecimal(42))
    end

    it 'returns the decimal value of a String' do
      expect(Buckaruby::Amount.new('42').to_d).to eq(BigDecimal(42))
    end

    it 'returns the decimal value of a String with decimals' do
      expect(Buckaruby::Amount.new('12.34').to_d).to eq(BigDecimal('12.34'))
    end
  end

  describe '#to_s' do
    it 'converts an Integer to a String representation' do
      expect(Buckaruby::Amount.new(42).to_s).to eq('42.00')
    end

    it 'converts a String to a String representation' do
      expect(Buckaruby::Amount.new('42').to_s).to eq('42.00')
    end

    it 'converts a String with decimals to a String representation' do
      expect(Buckaruby::Amount.new('12.34').to_s).to eq('12.34')
    end

    it 'converts a BigDecimal to a String representation' do
      expect(Buckaruby::Amount.new(BigDecimal('1.23')).to_s).to eq('1.23')
    end
  end
end
