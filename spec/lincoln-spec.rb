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

    config = YAML::load(IO.read("./shipping-quote-lincoln.yml"))
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



# SELECT custID, a.ref01, qty, a.isGlass, backorder, unit_weight weight, glassConverter, ormd, shipCode
# FROM cart_items a, syscatalog.dbo.catalog b, syscatalog.dbo.catalog_reference c
# where a.item = b.id
# and a.item = c.item
# and companyid = 2
# and cartid = 636274
# order by a.id desc

#  [ ref01 qty isGlass backorder weight  glassConverter
# { 'ref01'=>'FETS710' 2 NULL  0 2.00  NULL
# { 'ref01'=>'UF5523296' 1 NULL  0 0.60  NULL
# { 'ref01'=>'410198'  40  NULL  0 0.40  NULL
# { 'ref01'=>'S533.3F' 1 1 0 6.40  1
# { 'ref01'=>'S523.2F' 1 1 0 0.00  1
# { 'ref01'=>'S528.1F' 1 1 1 0.00  1
# { 'ref01'=>'S4000.9F'  1 1 0 6.50  NULL
# { 'ref01'=>'U112996' 1 1 0 0.00  1




      it 'dichro test' do
        destination = {'country'=>'US', 'street'=>'31 Cliff Way', 'street2'=>'', 'province'=>'NY', 'city'=>'Baiting Hollow', 'postal_code'=>'11933', 'price_class'=>'1' }
        cart_items = [
          { 'item'=>'195287', 'ref01'=>'105412', 'qty'=>'2', 'isGlass'=>'3', 'backorder'=>'25' }
        ]

        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)
        puts results
      end

      it 'high number of glass flips to truck_only' do
        destination = {'country'=>'US', 'street'=>'31 Cliff Way', 'street2'=>'', 'province'=>'NY', 'city'=>'Baiting Hollow', 'postal_code'=>'11933', 'price_class'=>'1' }
        cart_items = [
          { 'qty'=>'2', 'ref01'=>'X21071-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X22672-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'2', 'ref01'=>'X100-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '1', 'weight'=>'0.00', 'isGlass'=>'1', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X20PK', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'10.00', 'isGlass'=>'0', 'shipCode'=>'UPS', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'X4027', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'6.00', 'isGlass'=>'0', 'shipCode'=>'GLA', 'fs'=>'0' },
          { 'qty'=>'1', 'ref01'=>'XS56', 'backorder'=>'0', 'ormd'=>'0', 'glassConverter'=> '', 'weight'=>'0.38', 'isGlass'=>'0', 'shipCode'=>' NPA', 'fs'=>'0' },
          { 'qty'=>'17', 'ref01'=>'M3906-MD', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '3', 'weight'=>'1.05', 'isGlass'=>'1', 'shipCode'=>'', 'fs'=>'0' }
        ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, config)
        results = ship.runner(d_symbol)

        has_truck = results.select{|key, value| key.to_s.match(/^Truck Shipping/)}
        expect(has_truck.length).to eq(1)
      end



    end
  end
end
