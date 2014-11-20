require 'spec_helper'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    # let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 5, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    # let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item) { double('item', ref01: 's100rr-md', shipCode: 'UPS', isGlass: 1, qty: 25, weight: 0, backorder: 0, vendor: 10, ormd: nil, glassConverter: 4, freeShipping: 0) }
    let!(:item2) { double('item', ref01: 's111w-md', shipCode: 'UPS', isGlass: 1, qty: 33, weight: 0, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    cart_items = []
    describe 'glass shipping' do


     xit 'returns 58 md glass quote' do
       cart_items[0] = item
       cart_items[1] = item2
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)

       puts results
     end
     it 'returns 35 lg glass quote' do

       item.stub(:ref01).and_return('A01479S-LG')
       item.stub(:shipCode).and_return('GLA')
       item.stub(:qty).and_return(35)
       cart_items[0] = item
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)

       puts results
     end
    end
  end
end

