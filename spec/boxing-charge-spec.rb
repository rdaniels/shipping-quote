require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do
    # let(:output) { double('output').as_null_object }
    # let(:shipping) { Shipping.new }

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
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
        expect(ship.calculate_boxing(0, 1, 0)).to eq(config[:first_glass_box_extra_charge].to_f + config[:sm_glass_box_charge].to_f)
      end

      it 'adds boxing charge from create packages' do
        config[:add_boxing_charge] = true
        item.stub(:isGlass).and_return(1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        ship.create_packages
        expect(ship.boxing_charge).to eq(config[:sm_glass_box_charge].to_f + config[:first_glass_box_extra_charge].to_f)
      end

      it 'charges 8.50 for extra boxing' do
        config[:add_boxing_charge] = true
        config[:extra_boxing] = 'sadfg 8601 abc123'
        config[:extra_boxing_charge] = 8.5
        item.stub(:ref01).and_return('8601')

        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        ship.create_packages
        expect(ship.boxing_charge).to eq(8.5)
      end

      it 'does not add extra boxing' do
        config[:add_boxing_charge] = true
        config[:extra_boxing] = 'sadfg 8601 abc123'
        config[:extra_boxing_charge] = 8.5
        item.stub(:ref01).and_return('601')

        cart_items[0] = item
        cart_items[1] = item2
        ship = Shipping.new(cart_items, config)
        ship.create_packages
        expect(ship.boxing_charge).to eq(0)
      end

    end
  end
end

