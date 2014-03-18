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



    describe 'JSON tests' do
      destination = {"province"=>"FL", "country"=>"US", "postal_code"=>33609, "city"=>"Tampa", "street"=>"1234 fake street", "street2"=>""}
      cart_items = [
        {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>1, "qty"=>1, "ref01"=>"3000", "backorder"=>0, "ormd"=>"", "freeShipping"=>2, "isGlass"=>""},
        {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>5, "qty"=>1, "ref01"=>"ab123", "backorder"=>0, "ormd"=>"", "freeShipping"=>0, "isGlass"=>""}]
      c_hash = []
      cart_items.each {|item| c_hash << Hashit.new(item) }
      d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}



      it "country = 'US', street = 'po box 41246', street2 = '', province = 'TN', city = 'NASHVILLE', postal_code = '37204' "
      it "country = 'US', street = '83 maple ave', street2 = '', province = 'ct', city = 'windsor', postal_code = '06095' "




      it 'returns fedex express saver and home ground' do
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        #puts results
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_express.length).to eq(1)
        expect(has_ground.length).to be > 0
      end

      it 'does not return string to fixnum error' do
        destination = {"province"=>"LA", "country"=>"US", "postal_code"=>"70630-5118", "city"=>"BELL CITY", "street"=>"268 SWEET LAKE CAMP RD", "street2"=>""}
        cart_items = [
        {"shipCode"=>"UPS", "glassConverter"=>"2", "weight"=>"", "qty"=>"2", "ref01"=>"B20373F-LG", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"}]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}

        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results.length).to be > 0
      end

      xit 'returns for St. Louis with glass items' do
        destination = {"province"=>"MO", "country"=>"US", "postal_code"=>63116-3903, "city"=>"SAINT LOUIS", "street"=>"3956 CONNECTICUT ST", "street2"=>""}
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        puts results
        #expect(results.length).to be > 0
      end
    end

  end
end

