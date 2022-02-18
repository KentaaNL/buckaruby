# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::Configuration do
  describe '#website' do
    it 'sets the website from options' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect(config.website).to eq('12345678')
    end

    it 'raises an exception when website is missing' do
      config = Buckaruby::Configuration.new(secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect { config.website }.to raise_error(ArgumentError)
    end
  end

  describe '#secret' do
    it 'sets the secret from options' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect(config.secret).to eq('7C222FB2927D828AF22F592134E8932480637C0D')
    end

    it 'raises an exception when secret is missing' do
      config = Buckaruby::Configuration.new(website: '12345678')
      expect { config.secret }.to raise_error(ArgumentError)
    end
  end

  describe '#hash_method' do
    it 'raises an exception when an invalid hash method is passed' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', hash_method: :invalid)
      expect { config.hash_method }.to raise_error(ArgumentError)
    end

    it 'accepts SHA-1 as hash method' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', hash_method: 'SHA1')
      expect(config.hash_method).to eq(:sha1)
    end

    it 'accepts SHA-256 as hash method' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', hash_method: :SHA256)
      expect(config.hash_method).to eq(:sha256)
    end

    it 'accepts SHA-512 as hash method' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', hash_method: :sha512)
      expect(config.hash_method).to eq(:sha512)
    end
  end

  describe '#test?' do
    it 'returns false as default' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect(config.test?).to be false
    end

    it 'returns true when test is enabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: true)
      expect(config.test?).to be true
    end

    it 'returns false when test is disabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: false)
      expect(config.test?).to be false
    end
  end

  describe '#live?' do
    it 'returns true as default' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect(config.live?).to be true
    end

    it 'returns false when test is enabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: true)
      expect(config.live?).to be false
    end

    it 'returns true when test is disabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: false)
      expect(config.live?).to be true
    end
  end

  describe '#api_url' do
    it 'returns the live URL as default' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D')
      expect(config.api_url).to eq('https://checkout.buckaroo.nl/nvp/')
    end

    it 'returns the test URL when test is enabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: true)
      expect(config.api_url).to eq('https://testcheckout.buckaroo.nl/nvp/')
    end

    it 'returns the live URL when test is disabled' do
      config = Buckaruby::Configuration.new(website: '12345678', secret: '7C222FB2927D828AF22F592134E8932480637C0D', test: false)
      expect(config.api_url).to eq('https://checkout.buckaroo.nl/nvp/')
    end
  end
end
