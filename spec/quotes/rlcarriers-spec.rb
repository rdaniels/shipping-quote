require 'spec_helper'
# require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', name:'solder roll', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', name:'widget', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item3) { double('item', ref01: 'srakpak', name:'Spectrum Rack Pack - 80 Pieces', shipCode: 'TRK', isGlass: nil, qty: 1, weight: 145, backorder: 0, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }
    #let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'freight_request' do
      let(:cart_items[0]) { item }
      config[:free_shipping] = {}

      it 'calculates 60 lbs shipping' do
        item.stub(:weight).and_return('nil')
        cart_items[0] = item

        ship = RLQuote.new(cart_items, config)
        quote = ship.freight_request(destination)
        puts quote
      end


      # it 'returns ship calss 65 for 30 or more sheets of glass' do
      #   item.stub(:ref01).and_return('s100rr-lg')
      #   item2.stub(:ref01).and_return('s100g-sht')
      #   item.stub(:isGlass).and_return(1)
      #   item2.stub(:isGlass).and_return(1)
      #   (0..20).each { |i| cart_items[i] = item }
      #   (21..30).each { |i| cart_items[i] = item2 }
      #   ship = RLQuote.new(cart_items, config)
      #   expect(ship.ship_class).to eq(65)
      # end

      # it 'returns shipping quote greater than $20' do
      #   cart_items[0] = item
      #   ship = RLQuote.new(cart_items, config)
      #   quote = ship.freight_request(destination)
      #   expect(quote).to be > 20
      # end

      # it 'calculates 60 lbs shipping' do
      #   item.stub(:qty).and_return(5)
      #   item.stub(:weight).and_return(6)
      #   item2.stub(:qty).and_return(3)
      #   item2.stub(:weight).and_return(10)
      #   cart_items[0] = item
      #   cart_items[1] = item2

      #   ship = RLQuote.new(cart_items, config)
      #   expect(ship.get_weight).to eq(60)
      # end

      # it 'Runner returns only Truck Shipping over $40 if shipCode = TRK' do
      #   item.stub(:shipCode).and_return('TRK')
      #   cart_items[0] = item
      #   cart_items[1] = item2
      #   cart_items[2] = item3
      #   ship = Shipping.new(cart_items, config)
      #   quote = ship.runner(destination)
      #   expect(quote[0][0]).to eq('Truck Shipping')
      #   expect(quote.length).to eq(1)
      #   expect(quote[0][1]).to be > 40
      # end


      # it 'returns shipping quote less than $200' do
      #   item.stub(:shipCode).and_return('SHA')
      #   item.stub(:weight).and_return('12')
      #   item2.stub(:shipCode).and_return('GLA')
      #   item2.stub(:weight).and_return('8')
      #   cart_items[0] = item
      #   cart_items[1] = item2
      #   cart_items[2] = item3
      #   ship = RLQuote.new(cart_items, config)
      #   quote = ship.freight_request(destination)
      #   expect(quote[0][0]).to eq('Truck Shipping')
      #   expect(quote.length).to eq(1)
      #   expect(quote[0][1]).to be < 200
      # end




    end
  end
end

