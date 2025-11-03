# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby do
  describe '.config' do
    it 'has a default logger' do
      expect(Buckaruby.config.logger).to be_a(Logger)
    end

    it 'has default open_timeout and read_timeout' do
      expect(Buckaruby.config.open_timeout).to eq(30)
      expect(Buckaruby.config.read_timeout).to eq(30)
    end
  end

  describe '.configure' do
    it 'yields the config object' do
      yielded = nil
      Buckaruby.configure do |c|
        yielded = c
      end
      expect(yielded).to eq(Buckaruby.config)
    end

    it 'allows changing configuration values' do
      logger = Logger.new($stdout)

      Buckaruby.configure do |c|
        c.logger = logger
        c.open_timeout = 60
        c.read_timeout = 120
      end

      expect(Buckaruby.config.logger).to eq(logger)
      expect(Buckaruby.config.open_timeout).to eq(60)
      expect(Buckaruby.config.read_timeout).to eq(120)
    end

    it 'does not allow replacing the config object' do
      expect { Buckaruby.config = Buckaruby::Config.new }.to raise_error(NoMethodError)
    end
  end

  describe '.reset!' do
    let(:logger) { Logger.new($stdout) }

    before do
      Buckaruby.configure do |c|
        c.logger = logger
        c.open_timeout = 60
        c.read_timeout = 120
      end
    end

    it 'resets configuration to default values' do
      Buckaruby.reset!

      expect(Buckaruby.config.logger).to be_a(Logger)
      expect(Buckaruby.config.logger).not_to eq(logger)
      expect(Buckaruby.config.open_timeout).to eq(30)
      expect(Buckaruby.config.read_timeout).to eq(30)
    end

    it 'provides a fresh Config object' do
      old_config = Buckaruby.config
      Buckaruby.reset!
      expect(Buckaruby.config).not_to eq(old_config)
    end
  end
end
