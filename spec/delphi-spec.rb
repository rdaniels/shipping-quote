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

    describe 'create-packages' do
      describe 'calculate glass boxes' do
        it 'has 2 small glass boxes' do
          item.stub(:isGlass).and_return(1)
          to = config[:sm_per_box].to_f + 1
          (0..to).each { |i| cart_items[i] = item }
          ship = Shipping.new(cart_items, config)
          expect(ship.create_packages).to have(2).packages
        end
      end
    end

    describe 'quotes' do

      xit 'returns ups and usps for canada when entry in yml' do
        destination[:country] = 'CA'
        destination[:province] = 'ON'
        destination[:postal_code] = 'L5B2T4'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_ups = quote.select{|key, value| key.to_s.match(/^UPS Standard/)}
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_ups).to have(1).rates
        expect(has_usps).to have_at_least(1).rates
      end

      xit 'changes "United States" to "US" ' do
        destination[:country] = 'United States'
        ship = Shipping.new(cart_items, config)
        cart_items[0] = item
        results = ship.runner(destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        has_media = results.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_express).to have(1).rates
        expect(has_ground).to have(1).rates
        expect(has_usps).to have_at_least(1).rates
        expect(has_media).to have(0).rates
        #puts results
      end

      xit 'returns Media Mail if all cart items are MDA' do
        item.stub(:shipCode).and_return('MDA')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_express = results.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_express).to have(1).rates
      end
    end



  end
end

