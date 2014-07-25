require 'spec_helper'
## require 'pry'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: 's100rr-md', shipCode: 'UPS', isGlass: 1, qty: 25, weight: 0, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 's111w-md', shipCode: 'UPS', isGlass: 1, qty: 33, weight: 0, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'TX', :city => 'Burkburnett', :postal_code => '76354'} }

    cart_items = []

     it 'returns 58 md glass quote' do
       cart_items[0] = item
       cart_items[1] = item2
       ship = Shipping.new(cart_items, config)
       results = ship.runner(destination)

       puts results
     end

  end
end
