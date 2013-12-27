require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-spec.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }


    describe 'filter shipping' do
      it 'returns fedex express saver, home ground, and usps standard' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quotes = ship.quotes(destination,packages)
        results = ship.filter_shipping(quotes, destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_express).to have_at_least(1).rates
        expect(has_ground).to have_at_least(1).rates
        expect(has_usps).to have_at_least(1).rates
      end
      it 'returns truck option only if item has shipCode = TRK' do
        item.stub(:shipCode).and_return('TRK')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        truck_only = ship.truck_only
        packages = ship.create_packages
        quotes = ship.quotes(destination,packages)
        results = ship.filter_shipping(quotes, destination)
        expect(results).to have(1).rate
        has_truck = results.select{|key, value| key.to_s.match(/^Truck Shipping/)}
        expect(has_truck).to have(1).rate
      end
      it 'only returns ground when ormd' do
        item.stub(:ormd).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quotes = ship.quotes(destination,packages)
        results = ship.filter_shipping(quotes, destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_express).to have(0).rates
        expect(has_ground).to have_at_least(1).rates
        expect(has_usps).to have(0).rates
      end
      it 'returns multiple quotes for Canada' do
        destination = { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quotes = ship.quotes(destination,packages)
        results = ship.filter_shipping(quotes, destination)
        expect(results).to have_at_least(2).rates
      end

    end


    describe 'quotes' do


      it 'returns fedex express saver, home ground, and usps standard' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = quote.select{|key, value| key.to_s.match(/^FedEx Ground Home Delivery/)}
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Standard Post/)}
        expect(has_express).to have(1).rates
        expect(has_ground).to have(1).rates
        expect(has_usps).to have(1).rates
      end
      it 'quote without boxing code less than quote with boxing charge' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote = has_express[0][1]

        destination[:province] = 'CA'
        destination[:city] = 'Industry',
        destination[:postal_code] = '91745'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote_ca = has_express[0][1]
        expect(express_quote).to be < express_quote_ca
      end
      it 'quote to FL less than quote to California' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote = has_express[0][1]

        config[:add_boxing_charge] = true
        item.stub(:isGlass).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote_boxing = has_express[0][1]
        expect(express_quote).to be < express_quote_boxing
      end
    end


    describe 'truck only' do
      it 'UPS item returns truck_only as 0' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.truck_only).to be == 0
      end

      it 'TRK item returns truck_only as 1' do
        item.stub(:shipCode).and_return('TRK')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.truck_only).to be == 1
      end
    end
  end
end

