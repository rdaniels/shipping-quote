require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-spec.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    #let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }
    let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'quotes' do

      it 'returns ups and usps for canada when entry in yml' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        quote = ship.quotes(destination,packages)
        has_ups = quote.select{|key, value| key.to_s.match(/^UPS Standard/)}
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_ups).to have(1).rates
        expect(has_usps).to have_at_least(1).rates
      end

    end



  end
end

