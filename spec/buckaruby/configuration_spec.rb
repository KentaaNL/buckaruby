# frozen_string_literal: true

require 'spec_helper'

describe Buckaruby::Configuration do
  describe '#website' do
    it 'sets the website from options' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D")
      expect(config.website).to eq("12345678")
    end

    it 'raises an exception when website is missing' do
      expect {
        Buckaruby::Configuration.new(secret: "7C222FB2927D828AF22F592134E8932480637C0D")
      }.to raise_error(ArgumentError)
    end
  end

  describe '#secret' do
    it 'sets the secret from options' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D")
      expect(config.secret).to eq("7C222FB2927D828AF22F592134E8932480637C0D")
    end

    it 'raises an exception when secret is missing' do
      expect {
        Buckaruby::Configuration.new(website: "12345678")
      }.to raise_error(ArgumentError)
    end
  end

  describe '#mode' do
    it 'returns test when no mode is passed' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D")
      expect(config.mode).to eq(:test)
    end

    it 'returns test when mode test is passed' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :test)
      expect(config.mode).to eq(:test)
    end

    it 'returns production when mode production is passed' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :production)
      expect(config.mode).to eq(:production)
    end

    it 'raises an exception when an invalid mode is passed' do
      expect {
        Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :invalid)
      }.to raise_error(ArgumentError)
    end
  end

  describe '#hash_method' do
    it 'raises an exception when an invalid hash method is passed' do
      expect {
        Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :invalid)
      }.to raise_error(ArgumentError)
    end

    it 'accepts SHA-1 as hash method' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: 'SHA1')
      expect(config.hash_method).to eq(:sha1)
    end

    it 'accepts SHA-256 as hash method' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :SHA256)
      expect(config.hash_method).to eq(:sha256)
    end

    it 'accepts SHA-512 as hash method' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", hash_method: :sha512)
      expect(config.hash_method).to eq(:sha512)
    end
  end

  describe '#test?' do
    it 'returns true when mode is test' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :test)
      expect(config.test?).to be true
    end

    it 'returns false when mode is production' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :production)
      expect(config.test?).to be false
    end
  end

  describe '#production?' do
    it 'returns false when mode is test' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :test)
      expect(config.production?).to be false
    end

    it 'returns true when mode is production' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :production)
      expect(config.production?).to be true
    end
  end

  describe '#api_url' do
    it 'returns the test URL when mode is test' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :test)
      expect(config.api_url).to eq("https://testcheckout.buckaroo.nl/nvp/")
    end

    it 'returns the production URL when mode is production' do
      config = Buckaruby::Configuration.new(website: "12345678", secret: "7C222FB2927D828AF22F592134E8932480637C0D", mode: :production)
      expect(config.api_url).to eq("https://checkout.buckaroo.nl/nvp/")
    end
  end
end
