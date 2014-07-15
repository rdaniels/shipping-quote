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
    before(:each) do
      @config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
      @config[:free_shipping][:end_date] = '05-05-2050'
    end
    
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: 2) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 5, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609', :price_class => 1} }
    #let!(:destination) { { :country => 'CA', :province => 'ON', :city => 'Mississauga', :postal_code => 'L5B2T4'}  }

    describe 'sometimes free ship items' do
      
      it 'free shipping on glass triggered truck' do
        destination = {'country'=>'US', 'street'=>'31 Cliff Way', 'street2'=>'', 'province'=>'MI', 'city'=>'Charlevoix', 'postal_code'=>'49720-1101', 'price_class'=>'1' }
        cart_items = [{ 'qty'=>'40', 'ref01'=>'S100SDY-LG', 'backorder'=>'0', 'ormd'=>'', 'glassConverter'=> '3', 'weight'=>'0', 'isGlass'=>'1', 'shipCode'=>'LRG', 'freeShipping'=>'1' } ]
        c_hash = []
        cart_items.each {|item| c_hash << Hashit.new(item) }
        d_symbol = destination.inject({}){|memo,(k,v)| memo[k.to_sym] = v; memo}
        ship = Shipping.new(c_hash, @config)
        results = ship.runner(d_symbol)
        has_fedex = results.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
      end


      it 'free shipping for freeship=1 within end_date' do
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end

      it 'no free shipping for freeship=1 past end_date' do
        @config[:free_shipping][:end_date] = '1-1-2000'
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to be > 0
        expect(quote.length).to be > 1
      end

      it 'does not give free shipping when excluded price_class' do
        destination[:price_class] = 6
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to be > 0
      end

      it 'allow_free_ship = false blocks free shipping' do    
        item.stub(:freeShipping).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination, nil, false)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to be > 5
      end

      it 'allows free shipping to canada BC' do    
        destination[:price_class] = 1
        destination[:country] = 'CA'
        destination[:postal_code] = 'V8L 5N6'
        destination[:province] = 'BC'
        destination[:city] = 'North Saanich'
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_ups = quote.select{|key, value| key.to_s.match(/^UPS Standard/)}
        expect(has_ups[0][1]).to eq(0)
      end


      it 'no free shipping to canada YT' do   
        destination[:country] = 'CA'
        destination[:postal_code] = 'Y1A 1A3'
        destination[:province] = 'YT'
        destination[:city] = 'Whitehorse'
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS/)}
        expect(has_usps[0][1]).to be > 0
      end

    end


    describe 'always free ship items' do
      let(:cart_items[0]) { item }

      it 'returns free FedEx ground for 1 item with U_FreeShip = 2' do
        @config[:free_shipping][:end_date] = '1-1-2000'
        item.stub(:freeShipping).and_return(2)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end

      it 'allow_free_ship = false allows always free' do
        item.stub(:freeShipping).and_return(2)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination, nil, false)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        expect(has_fedex[0][1]).to eq(0)
      end

      it 'returns free First-Class Parcel when item qualifies' do
        item.stub(:freeShipping).and_return(2)
        item.stub(:weight).and_return(0.1)
        item.stub(:shipCode).and_return('UPS')
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
        expect(has_usps[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end

      it 'returns free Media Mail when item qualifies' do
        item.stub(:freeShipping).and_return(2)
        item.stub(:weight).and_return(0.6)
        item.stub(:shipCode).and_return('MDA')
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_usps[0][1]).to eq(0)
        expect(quote.length).to be > 1
      end
    end


    describe 'comparison test' do
      it 'returns lowest priced ship method' do
        item.stub(:freeShipping).and_return(0)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        expect(ship.lowest_priced).to eq('FedEx Ground')
      end

      it 'quote with free ship items less than quote without' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        fedex_quote = has_fedex[0][1]

        item.stub(:freeShipping).and_return(0)
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_fedex = quote.select{|key, value| key.to_s.match(/^FedEx Ground/)}
        fedex_quote_ca = has_fedex[0][1]
        expect(fedex_quote).to be > fedex_quote_ca
        expect(fedex_quote).to be > 0
        expect(fedex_quote_ca).to be > 0
      end
    end


    describe 'validate_date' do
      let(:cart_items[0]) { item }

      it 'returns false if no start or end date' do
        @config[:free_shipping][:start_date] = nil
        @config[:free_shipping][:end_date] = nil
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_date).to eq(true)
      end
      it 'returns true if today between start_date and end_date' do
        @config[:free_shipping][:start_date] = Date.yesterday
        @config[:free_shipping][:end_date] = Date.tomorrow
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_date).to eq(true)
      end
      it 'returns false if today not between start_date and end_date' do
        @config[:free_shipping][:start_date] = Date.yesterday
        @config[:free_shipping][:end_date] = Date.yesterday
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_date).to eq(false)
      end
      it 'returns false if today after start_date and start_date is string' do
        @config[:free_shipping][:start_date] = '1/1/2100'
        @config[:free_shipping][:end_date] = Date.tomorrow
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_date).to eq(false)
      end
    end

    describe 'validate_location' do
      let(:cart_items[0]) { item }
      it 'returns true for Florida' do
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_location(destination)).to eq(true)
      end
      # it 'returns false for Canada' do
      #   destination[:country] = 'CA'
      #   ship = FreeShipping.new(cart_items, @config)
      #   expect(ship.validate_location(destination)).to eq(false)
      # end
      it 'returns false for Hawaii' do
        destination[:province] = 'HI'
        ship = FreeShipping.new(cart_items, @config)
        expect(ship.validate_location(destination)).to eq(false)
      end

      it 'does not return free FedEx ground for 1 when country = AR' do
        destination[:country] = 'AR'
        destination[:postal_code] = '1426'
        destination[:province] = 'Capital Federal'
        destination[:city] = ''
        cart_items[0] = item
        ship = Shipping.new(cart_items, @config)
        quote = ship.runner(destination)
        has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail International/)}
        expect(has_usps[0][1]).to be > 0
        expect(quote.length).to be > 1
      end
    end
  end
end

