require 'spec_helper'


class Hashit
  def initialize(hash)
    hash.each do |k,v|
      self.instance_variable_set("@#{k}", v)  ## create and initialize an instance variable for this key/value pair
      self.class.send(:define_method, k, proc{self.instance_variable_get("@#{k}")})  ## create the getter that returns the instance variable
      self.class.send(:define_method, "#{k}=", proc{|v| self.instance_variable_set("@#{k}", v)})  ## create the setter that sets the instance variable
    end
  end
end


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


      it 'calculates commercial to CA' do
        item.stub(:shipCode).and_return('TRK') 
        destination[:country] = 'CA'
        destination[:postal_code] = 'G0L1A0'
        destination[:province] = 'QB'
        destination[:city] = 'Eastern Quebec'
        destination[:commercial] = 'N'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        destination[:commercial] = 'Y'
        quote2 = ship.runner(destination)
        expect(quote[0][1]).to be > quote2[0][1]
      end


      it 'returns ship calss 65 for 30 or more sheets of glass' do
        item.stub(:ref01).and_return('s100rr-lg')
        item2.stub(:ref01).and_return('s100g-sht')
        item.stub(:isGlass).and_return(1)
        item2.stub(:isGlass).and_return(1)
        (0..20).each { |i| cart_items[i] = item }
        (21..30).each { |i| cart_items[i] = item2 }
        ship = RLQuote.new(cart_items, config)
        expect(ship.ship_class).to eq(65)
      end

      it 'returns shipping quote greater than $20' do
        cart_items[0] = item
        ship = RLQuote.new(cart_items, config)
        quote = ship.freight_request(destination)
        expect(quote).to be > 20
      end

      it 'calculates 60 lbs shipping' do
        item.stub(:qty).and_return(5)
        item.stub(:weight).and_return(6)
        item2.stub(:qty).and_return(3)
        item2.stub(:weight).and_return(10)
        cart_items[0] = item
        cart_items[1] = item2

        ship = RLQuote.new(cart_items, config)
        expect(ship.get_weight).to eq(60)
      end

      it 'truck handle ref01 as fixnum' do
        cart_items = [
          {"shipCode"=>"TRK", "glassConverter"=>"", "weight"=>50, "qty"=>1, "ref01"=>3000, "backorder"=>0, "ormd"=>"", "freeShipping"=>0, "isGlass"=>""}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }        
        ship = RLQuote.new(c_hash, config)
        quote = ship.freight_request(destination)
        expect(quote).to be > 20
      end


      it 'does not ship truck to MX' do       
        item.stub(:shipCode).and_return('TRK') 
        destination[:country] = 'MX'
        destination[:postal_code] = '06140'
        destination[:province] = 'DF'
        destination[:city] = 'Mexico D.F.'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        expect(quote.length).to eq(0)
      end

      it 'Runner returns only Truck Shipping over $40 if shipCode = TRK' do
        item.stub(:shipCode).and_return('TRK')
        cart_items[0] = item
        cart_items[1] = item2
        cart_items[2] = item3
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        expect(quote[0][0]).to eq('Truck Shipping')
        expect(quote.length).to eq(1)
        expect(quote[0][1]).to be > 4000
        expect(quote[0][1]).to be < 20000
        #puts quote
      end

    end
  end
end

