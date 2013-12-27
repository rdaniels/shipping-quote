require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-spec.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 2, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) {
      {:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'}
    }


    describe 'boxing charges' do
      it 'returns single glass boxing charge' do
        config[:add_boxing_charge] = true
        ship = Shipping.new(cart_items, config)
        expect(ship.calculate_boxing(0, 1, 0)).to eq(config[:first_glass_box_extra_charge] + config[:sm_glass_box_charge])
      end
      it 'adds boxing charge from create packages' do
        config[:add_boxing_charge] = true
        item.stub(:isGlass).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        ship.create_packages
        expect(ship.boxing_charge).to eq(config[:sm_glass_box_charge] + config[:first_glass_box_extra_charge])
      end
    end


    describe 'create packages' do
      it 'nil returns no packages' do
        ship = Shipping.new(nil, config)
        expect(ship.create_packages).to be == []
      end

      it 'returns missing item weight in note and no packages' do
        item.stub(:weight).and_return(nil)
        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(0).packages
        expect(ship.notes).to eq('Item 3000 is missing weight.')
      end

      it 'nil allowed in vendor and shipCode for special order item' do
        #item.stub(:shipCode).and_return(nil)
        item.stub(:vendor).and_return(nil)
        item.stub(:backorder).and_return(21)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end

      it 'SHA item returns 1 package' do
        item.stub(:shipCode).and_return('SHA')
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end

      it 'single UPS item under box max weight returns 1 package' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end

      it '4 UPS items under box max weight returns 1 package' do
        cart_items[0] = item
        cart_items[1] = item
        cart_items[2] = item
        cart_items[3] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end

      it '2 UPS items over box max weight returns 2 packages' do
        item.stub(:weight).and_return(20)
        cart_items[0] = item
        cart_items[1] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it '3 UPS items over box max weight returns 2 packages' do
        cart_items[0] = item2
        cart_items[1] = item2
        cart_items[2] = item

        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it '1 special order item + 1 UPS item under box max weight returns 2 packages' do
        cart_items[0] = item
        item.stub(:backorder).and_return(21)
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it '2 special order items + 1 UPS item under box max weight returns 2 packages' do
        cart_items[0] = item2
        item.stub(:backorder).and_return(21)
        cart_items[1] = item
        cart_items[2] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it 'random number of lead items returns 1 package' do
        item.stub(:shipCode).and_return('LEA')
        (0..Random.rand(3...20)).each { |i| cart_items[i] = item }
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end
    end


  end
end

