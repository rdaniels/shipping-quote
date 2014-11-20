require 'spec_helper'

module ShippingQuote
  config = YAML::load(IO.read("./shipping-quote-delphi.yml"))

  describe CreatePackages do
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'SHA', length: 7, width: 8, height: 9, isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'SHA', length: 10, width: 11, height: 12, isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) {{:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    describe 'sha packages with sizing' do
      it 'return sized package' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = CreatePackages.new(ship.cart_items, config, destination)
        my_box = packages.package_runner
        expect(my_box[0].inches).to eq([7,8,9])
      end

      it 'returns 2 sized package' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        packages = CreatePackages.new(ship.cart_items, config, destination)
        my_box = packages.package_runner
        expect(my_box[0].inches).to eq([7,8,9])
        expect(my_box[1].inches).to eq([10,11,12])
      end

      it 'goes to default 10 x 10 x 10 if any size is 0' do
        item.stub(:length).and_return(0)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = CreatePackages.new(ship.cart_items, config, destination)
        my_box = packages.package_runner
        # puts my_box[0].inches
        expect(my_box[0].inches).to eq([10,10,10])
      end



      it 'handles size with string datatype' do
        item.stub(:length).and_return('40')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = CreatePackages.new(ship.cart_items, config, destination)
        my_box = packages.package_runner
        puts my_box[0].inches
        #expect(my_box[0].inches).to eq([10,10,10])
      end
    end
  end
end
