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



      it 'returns FedEx express saver and home ground' do
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_express.length).to eq(1)
        expect(has_ground.length).to be > 0
      end

      it 'returns FedEx options' do
        destination = {"country"=>'US', 'street'=>'83 maple ave', 'street2'=>'', 'province'=>'ct', 'city'=>'windsor', 'postal_code' =>'06095' }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        has_express = results.select{|key, value| key.to_s.match(/^FedEx Express Saver/)}
        has_ground = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_express.length).to eq(1)
        expect(has_ground.length).to be > 0
      end

      it 'returns for St. Louis with glass items' do
        destination = {"province"=>"MO", "country"=>"US", "postal_code"=>'63116-3903', "city"=>"SAINT LOUIS", "street"=>"3956 CONNECTICUT ST", "street2"=>""}
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results.length).to be > 0
      end


      it 'returns FedEx options 36765-3802' do
        destination = {'country'=>'US', 'street'=>'8622 AL HIGHWAY 61', 'street2'=>'', 'province'=>'AL', 'city'=>'NEWBERN', 'postal_code'=>'36765-3802' }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results.length).to be > 0
      end


      it 'returns USPS options' do
        config[:us_carriers] << 'USPS'
        destination = {"country"=>'US', 'street'=>'po box 41246', 'street2'=>'', 'province'=>'TN', 'city'=>'NASHVILLE', 'postal_code'=>'37204' }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        has_usps = results.select{|key, value| key.to_s.match(/^USPS/)}
        expect(has_usps.length).to be > 0
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


      it 'gift card check' do
        cart_items = [
          {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>"0.01", "qty"=>"1", "ref01"=>"GC50", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"2", "isGlass"=>"0"}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        has_free = results.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
        expect(has_free[0][1]).to eq(0)
      end


      it 'truck test' do
        config[:us_carriers] << 'RL'
        config[:us_carriers] << 'FedEx'
        destination = {"country"=>'US', 'street'=>'215 KLEIN RD', 'street2'=>'', 'province'=>'PA', 'city'=>'GLENSHAW', 'postal_code'=>'15116-3015' }
        cart_items = [
          {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>"2.81", "qty"=>"1", "ref01"=>"6903", "backorder"=>"0", "ormd"=>"1", "freeShipping"=>"0", "isGlass"=>""},
          {"shipCode"=>"TRK", "glassConverter"=>"", "weight"=>"115.00", "qty"=>"1", "ref01"=>"SPREM", "backorder"=>"0", "ormd"=>"0", "freeShipping"=>"0", "isGlass"=>"0"}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        #puts results
        expect(results.length).to be > 0
      end


      it 'returns a free ship option' do
        destination = {'country'=>'US', 'street'=>'9 RIDGE RD', 'street2'=>'', 'province'=>'VA', 'city'=>'HARTFIELD', 'postal_code'=>'23071-3130' }
        cart_items = [
            {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>"6.00", "qty"=>"1", "ref01"=>"5375", "backorder"=>"2", "ormd"=>"0", "freeShipping"=>"2", "isGlass"=>""},
            {"shipCode"=>"GLA", "glassConverter"=>"", "weight"=>"12.00", "qty"=>"1", "ref01"=>"5371", "backorder"=>"2", "ormd"=>"0", "freeShipping"=>"2", "isGlass"=>""},
            {"shipCode"=>"GLA", "glassConverter"=>"", "weight"=>"6.00", "qty"=>"1", "ref01"=>"5366", "backorder"=>"0", "ormd"=>"0", "freeShipping"=>"2", "isGlass"=>""},
            {"shipCode"=>"GLA", "glassConverter"=>"", "weight"=>"6.00", "qty"=>"1", "ref01"=>"5368", "backorder"=>"0", "ormd"=>"0", "freeShipping"=>"2", "isGlass"=>""}
          ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results[0][1]).to eq(0)
      end


      it 'backorder=3 test - does not return a free ship option' do
        destination = {'country'=>'US', 'street'=>'9 RIDGE RD', 'street2'=>'', 'province'=>'VA', 'city'=>'HARTFIELD', 'postal_code'=>'23071-3130' }
        cart_items = [
            {"shipCode"=>"UPS", "glassConverter"=>"", "weight"=>"6.00", "qty"=>"1", "ref01"=>"5375", "backorder"=>"3", "ormd"=>"0", "freeShipping"=>"0", "isGlass"=>""}
          ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results[0][1]).to be > 0
      end

      it 'returns a free ship option' do
        destination = {'country'=>'US', 'street'=>'20 WINTERBERRY LN', 'street2'=>'', 'province'=>'NY', 'city'=>'EAST HAMPTON', 'postal_code'=>'11937-4335', 'price_class'=>'1' }
        cart_items = [
            {"shipCode"=>"GLA", "glassConverter"=>"", "weight"=>"6", "qty"=>"2", "ref01"=>"5368", "backorder"=>"0", "ormd"=>"0", "freeShipping"=>"2", "isGlass"=>""}
          ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results[0][1]).to eq(0)
      end

      it 'high number of glass flips to truck_only' do
        destination = {'country'=>'US', 'street'=>'31 Cliff Way', 'street2'=>'', 'province'=>'NY', 'city'=>'Baiting Hollow', 'postal_code'=>'11933', 'price_class'=>'1' }
        cart_items = [
          { 'qty'=>'12', 'ref01'=>'X21071-LG', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X22672-LG', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'2', 'ref01'=>'X100-LG', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X20PK', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'10.00', 'isGlass'=>'0', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X4027', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'6.00', 'isGlass'=>'0', 'shipCode'=>'GLA', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'XS56', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'0.38', 'isGlass'=>'0', 'shipCode'=>' NPA', 'fs'=>'0' },
          { 'qty'=>'17', 'ref01'=>'M3906-LG', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '3', 'weight'=>'1.05', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0' }
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)

        has_truck = results.select{|key, value| key.to_s.match(/^Truck Shipping/)}
        #puts results
        expect(has_truck.length).to eq(1)
      end

      it 'returns quote' do
        destination = {'country'=>'US', 'street'=>'6850 S ROLLING HILLS DR', 'street2'=>'', 'province'=>'MI', 'city'=>'TRAVERSE CITY', 'postal_code'=>'49684-6505', 'price_class'=>'4' }
        cart_items = [
            {"shipCode"=>"", "glassConverter"=>"3", "weight"=>"", "qty"=>"3", "ref01"=>"B110038-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"2", "weight"=>"", "qty"=>"5", "ref01"=>"B010038-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"LRG", "glassConverter"=>"2", "weight"=>"0.00", "qty"=>"5", "ref01"=>"B110151-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"2", "weight"=>"8", "qty"=>"2", "ref01"=>"B012030-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"LRG", "glassConverter"=>"2", "weight"=>"0", "qty"=>"2", "ref01"=>"B032030-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"2", "weight"=>"8", "qty"=>"3", "ref01"=>"B011630-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"2", "weight"=>"8", "qty"=>"3", "ref01"=>"B012630-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"1", "weight"=>"", "qty"=>"3", "ref01"=>"B002430-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"},
            {"shipCode"=>"", "glassConverter"=>"2", "weight"=>"", "qty"=>"3", "ref01"=>"B013730-SHT", "backorder"=>"0", "ormd"=>"", "freeShipping"=>"0", "isGlass"=>"1"}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results.length).to be > 0
      end

      it 'ormd items show in notes' do
        destination = {'country'=>'CA', 'street'=>'', 'street2'=>'', 'province'=>'ON', 'city'=>'', 'postal_code'=>'N1R1C8', 'price_class'=>'1' }
        cart_items = [
            {'qty'=>'1', 'ref01'=>'2028', 'backorder'=>'0', 'glassConverter'=>'', 'weight'=>'0.6',  'isGlass'=>'0', 'ormd'=>'1', 'shipCode'=>'UPS', 'fs'=>'0'}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(ship.notes.length).to be > 1
      end




      it 'returns quote' do
        destination = {'country'=>'GU', 'street'=>'31 Cliff Way', 'street2'=>'', 'province'=>'GU', 'city'=>'Baiting Hollow', 'postal_code'=>'00918', 'price_class'=>'1' }
        cart_items = [
            {'qty'=>'1', 'ref01'=>'S161RR-LG', 'backorder'=>'0', 'glassConverter'=>'3', 'weight'=>'0.00',  'isGlass'=>'1', 'shipCode'=>'LRG', 'fs'=>'0'},
            {'qty'=>'1', 'ref01'=>'S152RR-LG', 'backorder'=>'0', 'glassConverter'=>'3', 'weight'=>'0.00',  'isGlass'=>'1', 'shipCode'=>'LRG', 'fs'=>'0'},
            {'qty'=>'1', 'ref01'=>'S111RR-LG', 'backorder'=>'0', 'glassConverter'=>'3', 'weight'=>'', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0'},
            {'qty'=>'1', 'ref01'=>'S100RR-LG', 'backorder'=>'0', 'glassConverter'=>'3', 'weight'=>'0.00',  'isGlass'=>'1', 'shipCode'=>'LRG', 'fs'=>'0'},
            {'qty'=>'1', 'ref01'=>'S1009-MD', 'backorder'=>'0', 'glassConverter'=>'3', 'weight'=>'0.00',  'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0'},
            {'qty'=>'1', 'ref01'=>'Y5002SP-MD', 'backorder'=>'0', 'glassConverter'=>'2', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=> '0'},
            {'qty'=>'1', 'ref01'=>'Y1100SP-MD', 'backorder'=>'0', 'glassConverter'=>'2', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>' 0'}
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        #puts results
        expect(results.length).to be > 0
      end

      
      it 'po box does not return fedex'  do
        destination = {'country'=>'US', 'street'=>'P. O. Box 5884', 'street2'=>'', 'province'=>'Az', 'city'=>'Glendale', 'postal_code'=>'85312', 'price_class'=>'1' }
        cart_items = [
          { 'qty'=>'2', 'ref01'=>'X21071-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X22672-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0' }
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        has_fedex = results.select{|key, value| key.to_s.match(/^FedEx/)}
        expect(has_fedex.length).to eq(0)
      end


      it 'returns a reasonable quote'  do
        destination = {'country'=>'CA', 'street'=>'', 'street2'=>'', 'province'=>'ON', 'city'=>'', 'postal_code'=>'L2J4E3', 'price_class'=>'1' }
        cart_items = [
           { 'qty'=>2, 'ref01'=>'63755-MD', 'backorder'=>'0', 'glassConverter'=>'1', 'weight'=>0.24, 'isGlass'=>'3', 'shipCode'=>'UPS', 'fs'=>'0' },
           { 'qty'=>60, 'ref01'=>'5237DB', 'backorder'=>'0', 'glassConverter'=>'', 'weight'=>0.13, 'isGlass'=>'0', 'shipCode'=>'UPS', 'fs'=>'0' },
           { 'qty'=>6, 'ref01'=>'MB332', 'backorder'=>'0', 'glassConverter'=>'', 'weight'=>0.31, 'isGlass'=>'', 'shipCode'=>'UPS', 'fs'=>'0' },
           { 'qty'=>6, 'ref01'=>'MB331', 'backorder'=>'0','glassConverter'=>'', 'weight'=>0.19, 'isGlass'=>'', 'shipCode'=>'UPS', 'fs'=>'0' }
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        expect(results.length).to be > 1
      end


    end
  end
end

