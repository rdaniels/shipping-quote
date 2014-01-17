require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', name:'solder roll', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', name:'widget', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }
    #let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'freight_request' do
      let(:cart_items[0]) { item }
      config[:free_shipping] = {}

      it 'returns ship calss 65 for 30 or more sheets of glass' do
        item.stub(:ref01).and_return('s100rr-lg')
        item2.stub(:ref01).and_return('s100g-sht')
        item.stub(:isGlass).and_return(1)
        item2.stub(:isGlass).and_return(1)
        (0..20).each { |i| cart_items[i] = item }
        (21..30).each { |i| cart_items[i] = item2 }

        ship = RLQuote.new(cart_items, config)
        ship_class = ship.ship_class
        expect(ship.ship_class).to eq(65)
      end

      it 'returns shipping quote greater than $20' do
        cart_items[0] = item
        ship = RLQuote.new(cart_items, config)
        quote = ship.freight_request(destination)
        expect(quote).to be > 20
      end

    end
  end
end

