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
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: 1, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'AU',:street => '1234 fake street', :province => 'Victoria', :city => 'Wandiligong', :postal_code => '3744'} }

    describe 'ORMD tests' do

      it 'blocks ormd to australia' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        expect(results.length).to eq(0)
      end

      it 'allows ormd to florida' do
        config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
        destination[:country] = 'US'
        destination[:postal_code] = '33609'
        destination[:province] = 'FL'
        destination[:city] = 'Tampa'
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        expect(results.length).to be > 0
      end

      it 'blocks ormd to alaska' do
        config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
        destination[:country] = 'US'
        destination[:postal_code] = '99518'
        destination[:province] = 'AK'
        destination[:city] = 'Anchorage'
        ship = Shipping.new(cart_items, config)
        results = ship.runner(destination)
        expect(results.length).to eq(0)
      end


      it 'returns a reasonable quote'  do
        destination = {'country' => "US", 'price_class' => "1", 'province' => "MD", 'postal_code' => "20634" }
        # {'country'=>'CA', 'street'=>'', 'street2'=>'', 'province'=>'ON', 'city'=>'', 'postal_code'=>'L2J4E3', 'price_class'=>'1' }
        cart_items =
        # [
        #    { 'qty'=>2, 'ref01'=>'63755-MD', 'backorder'=>'0', 'glassConverter'=>'1', 'weight'=>0.24, 'isGlass'=>'3', 'shipCode'=>'UPS', 'fs'=>'0' },
        #    { 'qty'=>60, 'ref01'=>'5237DB', 'backorder'=>'0', 'glassConverter'=>'', 'weight'=>0.13, 'isGlass'=>'0', 'shipCode'=>'UPS', 'fs'=>'0' },
        #    { 'qty'=>6, 'ref01'=>'MB332', 'backorder'=>'0', 'glassConverter'=>'', 'weight'=>0.31, 'isGlass'=>'', 'shipCode'=>'UPS', 'fs'=>'0' },
        #    { 'qty'=>6, 'ref01'=>'MB331', 'backorder'=>'0','glassConverter'=>'', 'weight'=>0.19, 'isGlass'=>'', 'shipCode'=>'UPS', 'fs'=>'0' }
        # ]


       [{"ref01"=>"SI100G-MD", "qty"=>"3.000000", "shipCode"=>"UPS", "glassConverter"=>3, "weight"=>'0.0', "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"X136-MD", "qty"=>"2.000000", "shipCode"=>"UPS", "glassConverter"=>1, "weight"=>'0.0', "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"S3372-MD", "qty"=>"2.000000", "shipCode"=>"UPS", "glassConverter"=>3, "weight"=>'0.0', "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"B2310F-sm", "qty"=>"1.000000", "shipCode"=>nil, "glassConverter"=>2, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"W058I-MD", "qty"=>"2.320000", "shipCode"=>nil, "glassConverter"=>nil, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"X121-MD", "qty"=>"2.000000", "shipCode"=>"UPS", "glassConverter"=>1, "weight"=>'0.0', "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"B013230-sm", "qty"=>"1.000000", "shipCode"=>nil, "glassConverter"=>2, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"X152-MD", "qty"=>"2.000000", "shipCode"=>nil, "glassConverter"=>2, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"W701LL-MD", "qty"=>"1.160000", "shipCode"=>nil, "glassConverter"=>4, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"W0191I-MD", "qty"=>"1.160000", "shipCode"=>nil, "glassConverter"=>nil, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"W2D-MD", "qty"=>"1.160000", "shipCode"=>nil, "glassConverter"=>4, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1},
        {"ref01"=>"W58G-MD", "qty"=>"2.320000", "shipCode"=>nil, "glassConverter"=>4, "weight"=>nil, "backorder"=>nil, "ormd"=>nil, "freeShipping"=>0, "isGlass"=>1}]


        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)

        expect(results.length).to be > 0
        #puts results
      end


    end


  end
end

