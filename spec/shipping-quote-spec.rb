require 'spec_helper'
require 'pry'

module ShippingGem
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }


    it 'returns no packages' do
      ship = Shipping.new(nil)
      expect(ship.create_packages).to be == []
    end

    describe 'create packages' do
      it 'sets truck_only to 1' do
        cart_items = []
        item = double('item',
          :shipCode => 'TRK',
          :isGlass => nil,
          :qty => 1,
          :weight => 1 )
        cart_items[0] = item


        ship = Shipping.new(cart_items)
        shipping = ship.create_packages
        truck = shipping.instance_variable_get(:@truck_only)
        binding.pry
        expect(truck).to be == 1
      end
    end
  end
end