require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 5, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    cart_items = []
    describe 'filter shipping' do

     it 'returns blank when quote <= boxing charge'

     it 'returns fedex express saver and home ground' do
       cart_items[0] = item
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)
       has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
       has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
       expect(has_express.length).to eq(1)
       expect(has_ground.length).to be > 0
     end
     it 'returns truck option only if item has shipCode = TRK' do
       item.stub(:shipCode).and_return('TRK')
       cart_items[0] = item
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)
       expect(results.length).to eq(1)
       has_truck = results.select{|key, value| key.to_s.match(/^Truck Shipping/)}
       expect(has_truck.length).to eq(1)
     end
     it 'only returns ground when ormd' do
       item.stub(:ormd).and_return(1)
       cart_items[0] = item
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)

       has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
       has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
       has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
       expect(has_express.length).to eq(0)
       expect(has_ground.length).to be > 0
       expect(has_usps.length).to eq(0)
     end
     it 'returns multiple quotes for Canada' do
       destination = { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}
       cart_items[0] = item
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)
       expect(results.length).to be > 1
     end
    end



    describe 'comparison tests' do

      it 'quote without boxing code less than quote with boxing charge' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote = has_express[0][1]
        item.stub(:isGlass).and_return(1)
        item.stub(:ref01).and_return('s100rr-md')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        express_quote_ca = has_express[0][1]
        expect(express_quote).to be < express_quote_ca
      end
      it 'quote to FL less than quote to California' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}

        destination[:postal_code] = '90210'
        destination[:province] = 'CA'
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        ca_express = quote.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        expect(has_express[0][1]).to be < ca_express[0][1]
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

