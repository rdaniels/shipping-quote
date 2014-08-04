require 'spec_helper'
# require 'pry'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, length: 13, width: 15, height: 13) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }


    describe 'international runner' do
        it 'ups returns service_code' do
            destination[:country] = 'PL'
            destination[:street] = 'Mostowa 15A'
            destination[:postal_code] = '87-100'
            destination[:province] = 'PL'
            destination[:city] = 'Toru'
            item.stub(:shipCode).and_return('SHA')
            item.stub(:weight).and_return(14)
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            results = ship.runner(destination)    
            has_usps = results.select{|key, value| key.to_s.match(/^UPS Worldwide Expedited/)}
            expect(has_usps[0][2]).to eq('08')
        end


      it 'returns USPS quote for VE with 5 digit zip' do
        destination[:country] = 'VE'
        destination[:postal_code] = '05030'
        destination[:province] = 'RUBIO'
        destination[:city] = ''
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_usps.length).to be > 0
      end

      it 'returns USPS quote for AR' do
        destination[:country] = 'AR'
        destination[:postal_code] = '1426'
        destination[:province] = 'Capital Federal'
        destination[:city] = ''
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_usps.length).to be > 0
      end

      it 'returns USPS quote for ZA' do
        destination[:country] = 'ZA'
        destination[:postal_code] = '5247'
        destination[:province] = 'East London'
        destination[:city] = 'Vincent Heights'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_usps.length).to be > 0
      end

      it 'returns USPS quote for VE with 4 digit zip' do
        destination[:country] = 'VE'
        destination[:postal_code] = '6023'
        destination[:province] = 'El TIgre'
        destination[:city] = 'Rahme'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_usps.length).to be > 0
      end

      it 'returns USPS & UPS quote for CA' do
        destination[:country] = 'CA'
        destination[:postal_code] = 'V8L 5N6'
        destination[:province] = 'BC'
        #destination[:province] = 'International'
        destination[:city] = 'North Saanich'
        config[:origin][:city] = 'Tempe'
        config[:origin][:state] = 'AZ'
        config[:origin][:country] = 'US'
        config[:origin][:zip] = '85281'
        config[:international_carriers] = %w{USPS UPS RL}
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        has_ups = results.select{|key, value| key.to_s.match(/^UPS Standard/)}
        expect(has_usps.length).to be > 0
        expect(has_ups.length).to be > 0
      end

      it 'returns USPS & UPS quote for AU' do
        destination[:country] = 'AU'
        destination[:postal_code] = '3337'
        destination[:province] = 'Victoria'
        #destination[:province] = 'International'
        destination[:city] = 'Melton West'
        config[:origin][:city] = 'Lansing'
        config[:origin][:state] = 'MI'
        config[:origin][:country] = 'US'
        config[:origin][:zip] = '48910'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_ups = results.select{|key, value| key.to_s.match(/^UPS Saver/)}
        expect(has_ups.length).to be > 0
        #puts results
      end
    end
  end
end
