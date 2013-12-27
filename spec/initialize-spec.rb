require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-spec.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    describe 'runner' do
      it 'removes all fedex if po.box address' do
        destination[:street] = 'P.O. Box 1234'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_express).to have(0).rates
        expect(has_ground).to have(0).rates
        expect(has_usps).to have_at_least(1).rates
      end

      it 'filters if ship_selected' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination, 'FedEx Express Saver')
        expect(results).to have(1).rates
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        expect(has_express).to have(1).rates
      end

      it 'returns missing item weight in note and no packages' do
        item.stub(:weight).and_return(nil)
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        expect(ship.runner(destination)).to have(0).rates
        expect(ship.notes).to eq('Item 3000 is missing weight.')
      end
    end
  end
end