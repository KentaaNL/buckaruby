# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Support::CaseInsensitiveHash do
  describe 'retrieve and assign' do
    subject(:hash) { Buckaruby::Support::CaseInsensitiveHash.new }

    it 'accepts String keys and makes them case insensitive' do
      hash['foo'] = 'bar'
      hash['TesT'] = 'test'

      expect(hash['foo']).to eq('bar')
      expect(hash['FOO']).to eq('bar')
      expect(hash[:foo]).to eq('bar')

      expect(hash['test']).to eq('test')
      expect(hash['TEST']).to eq('test')
      expect(hash[:test]).to eq('test')
    end

    it 'accepts Symbol keys and makes them case insensitive' do
      hash[:foo] = 'bar'
      hash[:TEST] = 'test'

      expect(hash['foo']).to eq('bar')
      expect(hash['FOO']).to eq('bar')
      expect(hash[:foo]).to eq('bar')

      expect(hash['test']).to eq('test')
      expect(hash['TEST']).to eq('test')
      expect(hash[:test]).to eq('test')
    end

    it 'considers uppercase, lowercase and symbol with the same value as the same key' do
      hash[:foo] = 'bar'
      hash['foo'] = 'bar2'
      hash['FOO'] = 'bar3'

      expect(hash.keys.count).to eq(1)

      expect(hash[:foo]).to eq('bar3')
      expect(hash['foo']).to eq('bar3')
      expect(hash['FOO']).to eq('bar3')
    end
  end

  describe 'initialization' do
    context 'with String keys' do
      subject(:hash) { Buckaruby::Support::CaseInsensitiveHash.new('foo' => 'bar', 'test' => 'test') }

      it 'constructs a case insensitive hash' do
        expect(hash['foo']).to eq('bar')
        expect(hash['FOO']).to eq('bar')
        expect(hash[:foo]).to eq('bar')

        expect(hash['test']).to eq('test')
        expect(hash['TEST']).to eq('test')
        expect(hash[:test]).to eq('test')
      end
    end

    context 'with Symbol keys' do
      subject(:hash) { Buckaruby::Support::CaseInsensitiveHash.new(foo: 'bar', test: 'test') }

      it 'constructs a case insensitive hash' do
        expect(hash['foo']).to eq('bar')
        expect(hash['FOO']).to eq('bar')
        expect(hash[:foo]).to eq('bar')

        expect(hash['test']).to eq('test')
        expect(hash['TEST']).to eq('test')
        expect(hash[:test]).to eq('test')
      end
    end
  end
end
