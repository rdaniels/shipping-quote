require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }
    #let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'validate_date' do
      let(:cart_items[0]) { item }
      config[:free_shipping] = {}

      it 'returns false if no start or end date' do
        config[:free_shipping][:start_date] = nil
        config[:free_shipping][:end_date] = nil
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_date).to eq(false)
      end
      it 'returns true if today between start_date and end_date' do
        config[:free_shipping][:start_date] = Date.yesterday
        config[:free_shipping][:end_date] = Date.tomorrow
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_date).to eq(true)
      end
      it 'returns false if today not between start_date and end_date' do
        config[:free_shipping][:start_date] = Date.yesterday
        config[:free_shipping][:end_date] = Date.yesterday
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_date).to eq(false)
      end
      it 'returns false if today after start_date and start_date is string' do
        config[:free_shipping][:start_date] = '1/1/2100'
        config[:free_shipping][:end_date] = Date.tomorrow
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_date).to eq(false)
      end
    end

    describe 'validate_location' do
      let(:cart_items[0]) { item }
      it 'returns true for Florida' do
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_location(destination)).to eq(true)
      end
      it 'returns false for Canada' do
        destination[:country] = 'CA'
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_location(destination)).to eq(false)
      end
      it 'returns false for Hawaii' do
        destination[:state] = 'HI'
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_location(destination)).to eq(false)
      end
    end
  end
end

