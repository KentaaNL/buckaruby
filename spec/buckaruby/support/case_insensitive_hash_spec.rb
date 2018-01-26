# frozen_string_literal: true

require 'spec_helper'

describe Buckaruby::Support::CaseInsensitiveHash do
  describe 'retrieve and assign' do
    it 'accepts String keys and makes them case insensitive' do
      hash = Buckaruby::Support::CaseInsensitiveHash.new
      hash["foo"] = "bar"
      hash["TesT"] = "test"

      expect(hash["foo"]).to eq("bar")
      expect(hash["FOO"]).to eq("bar")
      expect(hash[:foo]).to eq("bar")

      expect(hash["test"]).to eq("test")
      expect(hash["TEST"]).to eq("test")
      expect(hash[:test]).to eq("test")
    end

    it 'accepts Symbol keys and makes them case insensitive' do
      hash = Buckaruby::Support::CaseInsensitiveHash.new
      hash[:foo] = "bar"
      hash[:TEST] = "test"

      expect(hash["foo"]).to eq("bar")
      expect(hash["FOO"]).to eq("bar")
      expect(hash[:foo]).to eq("bar")

      expect(hash["test"]).to eq("test")
      expect(hash["TEST"]).to eq("test")
      expect(hash[:test]).to eq("test")
    end

    it 'considers uppercase, lowercase and symbol with the same value as the same key' do
      hash = Buckaruby::Support::CaseInsensitiveHash.new
      hash[:foo] = "bar"
      hash["foo"] = "bar2"
      hash["FOO"] = "bar3"

      expect(hash.keys.count).to eq(1)

      expect(hash[:foo]).to eq("bar3")
      expect(hash["foo"]).to eq("bar3")
      expect(hash["FOO"]).to eq("bar3")
    end
  end

  describe 'initialization' do
    it 'constructs a case insensitive hash based on existing hash with String keys' do
      hash = Buckaruby::Support::CaseInsensitiveHash.new("foo" => "bar", "test" => "test")

      expect(hash["foo"]).to eq("bar")
      expect(hash["FOO"]).to eq("bar")
      expect(hash[:foo]).to eq("bar")

      expect(hash["test"]).to eq("test")
      expect(hash["TEST"]).to eq("test")
      expect(hash[:test]).to eq("test")
    end

    it 'constructs a case insensitive hash based on existing hash with Symbol keys' do
      hash = Buckaruby::Support::CaseInsensitiveHash.new(foo: "bar", test: "test")

      expect(hash["foo"]).to eq("bar")
      expect(hash["FOO"]).to eq("bar")
      expect(hash[:foo]).to eq("bar")

      expect(hash["test"]).to eq("test")
      expect(hash["TEST"]).to eq("test")
      expect(hash[:test]).to eq("test")
    end
  end
end
