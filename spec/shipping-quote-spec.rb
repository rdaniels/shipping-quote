require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    let!(:cart_items) { [] }
    let!(:item) { double('item', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10) }
    let!(:destination) {
      {:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'}
    }
    config = YAML::load(IO.read("./shipping-quote-spec.yml"))

    #TODO: refactor out ship=Shipping.new(cart_items)
    #before(:all) do
    #  ship = Shipping.new(cart_items)
    #end

    describe 'pull rate quotes' do
      it 'returns at least 1 rate' do

        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        packages = ship.create_packages
        expect(ship.quotes(destination,packages)).to have_at_least(1).fedex_rates
      end
    end

    describe 'create packages' do
      it 'nil returns no packages' do
        ship = Shipping.new(nil, config)
        expect(ship.create_packages).to be == []
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

      it 'multiple UPS items under box max weight returns 1 package' do
        cart_items[0] = item
        cart_items[1] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(1).packages
      end

      it '2 UPS items over box max weight returns 2 package' do
        item.stub(:weight).and_return(20)
        cart_items[0] = item
        cart_items[1] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it '1 special order item + 1 UPS item under box max weight returns 2 package' do
        cart_items[0] = item
        item.stub(:backorder).and_return(21)
        cart_items[1] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.create_packages).to have(2).packages
      end

      it '2 special order items + 1 UPS item under box max weight returns 2 package' do
        cart_items[0] = item
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


    describe 'boxing charges' do
      it 'returns single glass boxing charge' do
        config[:add_boxing_charge] = true
        ship = Shipping.new(cart_items, config)
        expect(ship.calculate_boxing(0, 1, 0)).to eq(config[:first_glass_box_extra_charge] + config[:sm_glass_box_charge])
      end
    end


    describe 'truck only check' do
      it 'UPS item returns truck_only as 0' do
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        expect(ship.truck_only).to be == 0
      end

      it 'TRK item returns truck_only as 1' do
        item.stub(:shipCode).and_return('TRK')
        cart_items[0] = item
        ship = Shipping.new(cart_items)
        expect(ship.truck_only).to be == 1
      end
    end
  end
end

