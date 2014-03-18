require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: 2) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 5, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609', :price_class => 1} }
    #let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'sometimes free ship items' do
      it 'free shipping for freeship=1 within end_date' do
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        #puts quote
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end

      it 'no free shipping for freeship=1 past end_date' do
        config[:free_shipping][:end_date] = '1-1-2000'
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to be > 0
        expect(quote.length).to be > 1
      end

      it 'does not give free shipping when excluded price_class' do
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        #puts quote
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to be > 0
      end

    end


    describe 'always free ship items' do
      let(:cart_items[0]) { item }
      config[:free_shipping] = {}

      it 'returns free FedEx ground for 1 item with U_FreeShip = 2' do
        config[:free_shipping][:end_date] = '1-1-2000'
        item.stub(:freeShipping).and_return(2)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end


      it 'returns free First-Class Parcel when item qualifies' do
        item.stub(:freeShipping).and_return(2)
        item.stub(:weight).and_return(0.1)
        item.stub(:shipCode).and_return('UPS')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        #puts quote
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
        expect(has_usps[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end

      it 'returns free Media Mail when item qualifies' do
        item.stub(:freeShipping).and_return(2)
        item.stub(:weight).and_return(0.6)
        item.stub(:shipCode).and_return('MDA')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        #puts quote
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_usps[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end
    end


    describe 'comparison test' do
      it 'quote with free ship items less than quote without' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        fedex_quote = has_fedex[0][1]

        item.stub(:freeShipping).and_return(0)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        fedex_quote_ca = has_fedex[0][1]
        expect(fedex_quote).to be > fedex_quote_ca
        expect(fedex_quote).to be > 0
        expect(fedex_quote_ca).to be > 0
      end
    end


    describe 'validate_date' do
      let(:cart_items[0]) { item }
      config[:free_shipping] = {}

      it 'returns false if no start or end date' do
        config[:free_shipping][:start_date] = nil
        config[:free_shipping][:end_date] = nil
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_date).to eq(true)
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
        destination[:province] = 'HI'
        ship = FreeShipping.new(cart_items, config)
        expect(ship.validate_location(destination)).to eq(false)
      end

      it 'does not return free FedEx ground for 1 when country = AR' do
        destination[:country] = 'AR'
        destination[:postal_code] = '1426'
        destination[:province] = 'Capital Federal'
        destination[:city] = ''
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail International/)}
        expect(has_usps[0][1]).to be > 0
        expect(quote.length).to be > 1
      end
    end
  end
end

