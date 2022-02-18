# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Buckaruby::FieldMapper do
  describe '.map_fields' do
    let(:fields) do
      {
        brq_services_1_description: 'iDEAL',
        brq_services_1_name: 'ideal',
        brq_services_1_version: '2',
        brq_services_1_supportedcurrencies_1_code: 'EUR',
        brq_services_1_supportedcurrencies_1_isonumber: '978',
        brq_services_1_supportedcurrencies_1_name: 'Euro',
        brq_services_2_description: 'Visa',
        brq_services_2_name: 'visa',
        brq_services_2_version: '1',
        brq_services_2_supportedcurrencies_1_code: 'GBP',
        brq_services_2_supportedcurrencies_1_isonumber: '826',
        brq_services_2_supportedcurrencies_1_name: 'Pond',
        brq_services_2_supportedcurrencies_2_code: 'USD',
        brq_services_2_supportedcurrencies_2_isonumber: '840',
        brq_services_2_supportedcurrencies_2_name: 'US Dollar'
      }
    end

    it 'maps NVP fields to arrays and hashes' do
      services = Buckaruby::FieldMapper.map_fields(fields, :brq_services)
      expect(services).to be_an_instance_of(Array)
      expect(services.count).to eq(2)

      ideal = services.first
      expect(ideal).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(ideal[:description]).to eq('iDEAL')
      expect(ideal[:name]).to eq('ideal')
      expect(ideal[:version]).to eq('2')

      visa = services.last
      expect(visa).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(visa[:description]).to eq('Visa')
      expect(visa[:name]).to eq('visa')
      expect(visa[:version]).to eq('1')
    end

    it 'maps NVP subfields to arrays and hashes' do
      services = Buckaruby::FieldMapper.map_fields(fields, :brq_services)

      currencies = services.first[:supportedcurrencies]
      expect(currencies).to be_an_instance_of(Array)
      expect(currencies.count).to eq(1)

      currency = currencies.first
      expect(currency).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(currency[:code]).to eq('EUR')
      expect(currency[:isonumber]).to eq('978')
      expect(currency[:name]).to eq('Euro')

      currencies = services.last[:supportedcurrencies]
      expect(currencies).to be_an_instance_of(Array)
      expect(currencies.count).to eq(2)

      currency = currencies.first
      expect(currency).to be_an_instance_of(Buckaruby::Support::CaseInsensitiveHash)
      expect(currency[:code]).to eq('GBP')
      expect(currency[:isonumber]).to eq('826')
      expect(currency[:name]).to eq('Pond')
    end
  end
end
