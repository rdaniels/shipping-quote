require 'spec_helper'
## require 'pry'

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

    describe 'create-packages' do
      describe 'calculate glass boxes' do
        it 'has 2 small glass boxes' do
          item.stub(:isGlass).and_return(1)
          item.stub(:ref01).and_return('s100rr-md')
          to = config[:sm_box2_pieces].to_d + 1
          (0..to).each { |i| cart_items[i] = item }
          ship = CreatePackages.new(cart_items, config, destination)
          expect(ship.create_packages(cart_items).length).to eq(2)
        end
      end
    end

    describe 'quotes' do
      it 'returns ups and usps for canada when entry in yml' do
        destination[:country] = 'CA'
        destination[:province] = 'ON'
        destination[:postal_code] = 'L5B2T4'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        #puts quote
        has_ups = quote.select{|key, value| key.to_s.match(/^UPS Standard/)}
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail International/)}
        expect(has_ups.length).to eq(1)
        expect(has_usps.length).to eq(1)
      end

      it 'changes "United States" to "US" ' do
        destination[:country] = 'United States'
        ship = Shipping.new(cart_items, config)
        cart_items[0] = item
        results = ship.runner(destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_media = results.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_express.length).to eq(1)
        expect(has_ground.length).to eq(1)
        expect(has_media.length).to eq(0)
      end

    end
  end
end

