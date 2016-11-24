require 'spec_helper'

describe Buckaruby::Signature do
  describe 'generate_signature_string' do
    it 'should ignore parameters that are not prefixed with brq_, add_ or cust_' do
      params = { abc: 'true', def: 'true', brq_test: 'true', add_test: 'true', cust_test: 'true' }
      string = Buckaruby::Signature.generate_signature_string(params, 'secret')
      expect(string).to eq('add_test=truebrq_test=truecust_test=truesecret')
    end

    it 'should ignore the brq_signature parameter' do
      params = { brq_test: 'true', add_test: 'true', cust_test: 'true', brq_signature: 'foobar' }
      string = Buckaruby::Signature.generate_signature_string(params, 'secret')
      expect(string).to eq('add_test=truebrq_test=truecust_test=truesecret')
    end

    it 'should accept boolean, integer and string as parameter types' do
      params = { brq_boolean: true, brq_integer: 1337, brq_string: 'foobar', brq_nil: nil }
      string = Buckaruby::Signature.generate_signature_string(params, 'secret')
      expect(string).to eq('brq_boolean=truebrq_integer=1337brq_nil=brq_string=foobarsecret')
    end

    it 'should generate a valid signature string' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar' }
      string = Buckaruby::Signature.generate_signature_string(params, 'secret')
      expect(string).to eq('brq_test=abcdefbrq_test2=foobarsecret')
    end

    it 'should sort parameters case insensitive and preserve casing in keys/values' do
      params = { BRQ_TESTB: 'abcDEF', brq_testA: 'Foobar', BRQ_TestC: 'test' }
      string = Buckaruby::Signature.generate_signature_string(params, 'secret')
      expect(string).to eq('brq_testA=FoobarBRQ_TESTB=abcDEFBRQ_TestC=testsecret')
    end
  end

  describe 'generate_signature' do
    it 'should raise an exception when generating a signature with an invalid hash method' do
      expect {
        params = { brq_test: 'abcdef', brq_test2: 'foobar' }
        Buckaruby::Signature.generate_signature(params, secret: 'secret', hash_method: :invalid)
      }.to raise_error(ArgumentError)
    end

    it 'should generate a valid signature with SHA-1 as hash method' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar' }
      string = Buckaruby::Signature.generate_signature(params, secret: 'secret', hash_method: :sha1)
      expect(string).to eq('c864c2abad67580274b2df00fd2a53739952b924')
    end

    it 'should generate a valid signature with SHA-256 as hash method' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar' }
      string = Buckaruby::Signature.generate_signature(params, secret: 'secret', hash_method: :sha256)
      expect(string).to eq('79afb9eac4182fdc2de222b558bcb0d3978f57bd4bf24eb2e7ea791943443716')
    end

    it 'should generate a valid signature with SHA-512 as hash method' do
      params = { brq_test: 'abcdef', brq_test2: 'foobar' }
      string = Buckaruby::Signature.generate_signature(params, secret: 'secret', hash_method: :sha512)
      expect(string).to eq('161e485fd71c708fa7f39c1732349fae1e5b8a0c05cd4f9d806ad570b2414f5b99b4aaf89ed48c55c188b82b9565d93471d3d20163002909360f31f29f4a988d')
    end
  end
end
