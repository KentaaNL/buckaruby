# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Signature do
  describe '.generate_params_string' do
    it 'ignores parameters that are not prefixed with brq_, add_ or cust_' do
      params = { abc: 'true', def: 'true', brq_test: 'true', add_test: 'true', cust_test: 'true' }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('add_test=truebrq_test=truecust_test=truesecret')
    end

    it 'ignores the brq_signature parameter' do
      params = { brq_test: 'true', add_test: 'true', cust_test: 'true', brq_signature: 'foobar' }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('add_test=truebrq_test=truecust_test=truesecret')
    end

    it 'accepts boolean, integer and string as parameter types' do
      params = { brq_boolean: true, brq_integer: 1337, brq_string: 'foobar', brq_nil: nil }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('brq_boolean=truebrq_integer=1337brq_nil=brq_string=foobarsecret')
    end

    it 'generates a valid signature string' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar' }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('brq_test=abcdefbrq_test2=foobarsecret')
    end

    it 'sorts parameters case insensitive and preserve casing in keys/values' do
      params = { BRQ_TESTB: 'abcDEF', brq_testA: 'Foobar', BRQ_TestC: 'test' }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('brq_testA=FoobarBRQ_TESTB=abcDEFBRQ_TestC=testsecret')
    end

    it 'sorts symbols first, then numbers, then case insensitive letters' do
      params = { 'brq_a_a' => 'foo', brq_a0: 'foo', brq_a0a: 'foo', brq_a1a: 'foo', brq_aaA: 'foo', brq_aab: 'foo', brq_aba: 'foo', brq_aCa: 'foo' }
      string = Buckaruby::Signature.generate_params_string('secret', params)
      expect(string).to eq('brq_a_a=foobrq_a0=foobrq_a0a=foobrq_a1a=foobrq_aaA=foobrq_aab=foobrq_aba=foobrq_aCa=foosecret')
    end
  end

  describe '.generate' do
    let(:config) { Buckaruby::Configuration.new(website: '12345678', secret: 'secret', hash_method: hash_method) }

    context 'with invalid hash method' do
      let(:hash_method) { :invalid }

      it 'raises an exception when generating a signature' do
        expect {
          params = { brq_test: 'abcdef', brq_test2: 'foobar' }
          Buckaruby::Signature.generate(config, params)
        }.to raise_error(ArgumentError)
      end
    end

    context 'with SHA-1 as hash method' do
      let(:hash_method) { :sha1 }

      it 'generates a valid signature' do
        params = { brq_test: 'abcdef', brq_test2: 'foobar' }
        string = Buckaruby::Signature.generate(config, params)
        expect(string).to eq('c864c2abad67580274b2df00fd2a53739952b924')
      end
    end

    context 'with SHA-256 as hash method' do
      let(:hash_method) { :sha256 }

      it 'generates a valid signature' do
        params = { brq_test: 'abcdef', brq_test2: 'foobar' }

        string = Buckaruby::Signature.generate(config, params)
        expect(string).to eq('79afb9eac4182fdc2de222b558bcb0d3978f57bd4bf24eb2e7ea791943443716')
      end
    end

    context 'with SHA-512 as hash method' do
      let(:hash_method) { :sha512 }

      it 'generates a valid signature' do
        params = { brq_test: 'abcdef', brq_test2: 'foobar' }
        string = Buckaruby::Signature.generate(config, params)
        expect(string).to eq('161e485fd71c708fa7f39c1732349fae1e5b8a0c05cd4f9d806ad570b2414f5b99b4aaf89ed48c55c188b82b9565d93471d3d20163002909360f31f29f4a988d')
      end
    end
  end

  describe '.verify!' do
    let(:config) { Buckaruby::Configuration.new(website: '12345678', secret: 'secret') }

    it 'raises a SignatureException when the signature is invalid' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar', brq_signature: 'abcdefgh1234567890abcdefgh1234567890' }
      expect {
        Buckaruby::Signature.verify!(config, params)
      }.to raise_error(Buckaruby::SignatureException, "Sent signature (abcdefgh1234567890abcdefgh1234567890) doesn't match generated signature (c864c2abad67580274b2df00fd2a53739952b924)")
    end

    it 'does not fail when the signature is valid' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar', brq_signature: 'c864c2abad67580274b2df00fd2a53739952b924' }
      Buckaruby::Signature.verify!(config, params)
    end
  end
end
