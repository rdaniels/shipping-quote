require 'spec_helper'
require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    let(:cart_items) { [] }
    let(:item) { double('item', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1 ) }

    #TODO: refactor out ship=Shipping.new(cart_items)
    #before(:all) do
    #  ship = Shipping.new(cart_items)
    #end

    describe 'create packages' do
      it 'nil returns no packages' do
        ship = Shipping.new(nil)
        expect(ship.create_packages).to be == []
      end

      it 'SHA item returns 1 package' do
        item.stub(:shipCode).and_return('SHA')
        cart_items[0] = item
        ship = Shipping.new(cart_items)
        expect(ship.create_packages).to have(1).packages
      end

      it 'single UPS item under box max weight returns 1 package' do
        cart_items[0] = item
        ship = Shipping.new(cart_items)
        expect(ship.create_packages).to have(1).packages
      end

      it 'multiple UPS items under box max weight returns 1 package' do
        cart_items[0] = item
        cart_items[1] = item
        ship = Shipping.new(cart_items)
        expect(ship.create_packages).to have(1).packages
      end

      it '2 UPS items over box max weight returns 2 package' do
        item.stub(:weight).and_return(20)
        cart_items[0] = item
        cart_items[1] = item
        ship = Shipping.new(cart_items)
        expect(ship.create_packages).to have(2).packages
      end

      it 'random number of lead items returns 1 package' do
        item.stub(:shipCode).and_return('LEA')
        (0..Random.rand(3...20)).each { |i| cart_items[i] = item }
        #puts cart_items.length
        ship = Shipping.new(cart_items)
        expect(ship.create_packages).to have(1).packages
      end
    end


    describe 'truck only check' do
      it 'UPS item returns truck_only as 0' do
        cart_items[0] = item
        ship = Shipping.new(cart_items)
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