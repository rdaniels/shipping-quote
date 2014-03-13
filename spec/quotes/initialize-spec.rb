require 'spec_helper'
# require 'pry'


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

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    describe 'runner' do
      it 'removes fedex and adds USPS if po.box address' do
        destination[:street] = 'P.O. Box 1234'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        has_usps = results.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
        expect(has_express.length).to eq(0)
        expect(has_ground.length).to eq(0)
        expect(has_usps.length).to be > 0
      end


      it 'returns missing item weight in note and no packages' do
        item.stub(:weight).and_return(nil)
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        expect(results.length).to eq(0)
        expect(ship.notes).to eq('Item 3000 is missing weight.')
      end


      it 'filters if ship_selected' do
        config[:us_carriers] = %w{USPS FedEx RL}
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination, 'FedEx Express Saver')
        #puts results.length
        expect(results.length).to eq(1)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        expect(has_express.length).to eq(1)
      end
    end

    describe 'JSON tests' do
        destination = {"province"=>"FL",
           "country"=>"US",
           "postal_code"=>33609,
           "city"=>"Tampa",
           "street"=>"1234 fake street",
           "street2"=>""}
        cart_items = [{"shipCode"=>"UPS",
            "glassConverter"=>"",
            "weight"=>1,
            "qty"=>1,
            "ref01"=>3000,
            "backorder"=>0,
            "ormd"=>"",
            "freeShipping"=>2,
            "isGlass"=>""},
           {"shipCode"=>"UPS",
            "glassConverter"=>"",
            "weight"=>5,
            "qty"=>1,
            "ref01"=>"ab123",
            "backorder"=>0,
            "ormd"=>"",
            "freeShipping"=>0,
            "isGlass"=>""}]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

        it 'returns fedex express saver and home ground' do
           ship = Shipping.new(c_hash, config)
           results = ship.runner(d_symbol)
           # puts results
           # has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
           # has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
           # expect(has_express.length).to eq(1)
           # expect(has_ground.length).to be > 0
         end
    end

  end
end

