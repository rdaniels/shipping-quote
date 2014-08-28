require 'spec_helper'

module ShippingQuote
  config = YAML::load(IO.read("./shipping-quote-delphi.yml"))

  describe CreatePackages do
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 2, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:destination) {{:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    config[:box_lead_weight] = 15
    describe 'lead packages' do
      it 'returns at lead weight if item weight < box_lead_weight' do
        item.stub(:shipCode).and_return('LEA')
        item.stub(:qty).and_return(2)
        item2.stub(:shipCode).and_return('LEA')
        item2.stub(:qty).and_return(3)
        item2.stub(:weight).and_return(1)
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.lead_packages(cart_items)
        expect(ship.packages.length).to eq(1) #have_1(:package)
        expect(ship.packages[0].weight / 16).to eq(config[:box_lead_weight])
      end

      it 'returns actual weight if items weight > box_lead_weight' do
        item.stub(:shipCode).and_return('LEA')
        item.stub(:qty).and_return(10)
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        ship.lead_packages(cart_items)
        expect(ship.packages.length).to eq(1) # have(1).package
        expect(ship.packages[0].weight / 16).to eq(20)
      end
    end

    describe 'special order' do
      it 'returns 1 stock item and 1 special order item' do
        item.stub(:backorder).and_return(21)
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.package_runner
        expect(ship.special_order_items.length).to eq(1)
        expect(ship.stock_items.length).to eq(1)
      end

      it 'returns 2 stock items and 0 special order item' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.package_runner
        expect(ship.special_order_items.length).to eq(0)
        expect(ship.stock_items.length).to eq(2)
      end

      it '1 special order item + 1 UPS item under box max weight returns 2 packages' do
        item.stub(:backorder).and_return(21)
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.package_runner.length).to eq(2) #have(2).packages
        expect(ship.special_order_items.length).to eq(1) #have(1).item
        expect(ship.stock_items.length).to eq(1) #have(1).item
      end

      it '2 special order items + 1 UPS item under box max weight returns 2 packages' do
        cart_items[0] = item2
        item.stub(:backorder).and_return(21)
        cart_items[1] = item
        cart_items[2] = item
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.package_runner.length).to eq(2)
        expect(ship.special_order_items.length).to eq(2)
        expect(ship.stock_items.length).to eq(1)
      end
    end

    #describe 'drop ship items' do
    #  it 'treats dropShip items as ship alone' do
    #    item.stub(:shipCode).and_return('DRP')
    #    cart_items[0] = item
    #    cart_items[1] = item2
    #    ship = CreatePackages.new(cart_items, config, destination)
    #    expect(ship.create_packages(cart_items)).to have(2).packages
    #  end
    #end

    describe 'create packages' do
      it 'SHA item returns 1 package' do
        item.stub(:shipCode).and_return('SHA')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = CreatePackages.new(ship.cart_items, config, destination)
        my_box = packages.create_packages(ship.cart_items)
        expect(my_box.length).to eq(1)
        expect(my_box[0].inches).to eq([10,10,10])
      end
      it 'returns missing item weight in note and no packages' do
        item.stub(:weight).and_return(nil)
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(0)
        expect(ship.notes).to eq('Item 3000 is missing weight.')
      end


      it 'single UPS item under box max weight returns 1 package' do
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(1)
      end

      it '4 UPS items under box max weight returns 1 package' do
        cart_items[0] = item
        cart_items[1] = item
        cart_items[2] = item
        cart_items[3] = item
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(1)
      end

      it '2 UPS items over box max weight returns 2 packages' do
        item.stub(:weight).and_return(20)
        cart_items[0] = item
        cart_items[1] = item
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(2)
      end

      it '3 UPS items over box max weight returns 2 packages' do
        cart_items[0] = item2
        cart_items[1] = item2
        cart_items[2] = item

        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(2)
      end



      it 'random number of lead items returns 1 package' do
        item.stub(:shipCode).and_return('LEA')
        (0..Random.rand(3...20)).each { |i| cart_items[i] = item }
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(1)
      end

      it 'nil returns no packages' do
        ship = CreatePackages.new(nil, config, destination)
        expect(ship.create_packages(cart_items).length).to eq(0)
      end
    end
  end

end

