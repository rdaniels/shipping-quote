require 'spec_helper'

module ShippingQuote
  describe CreatePackages do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: 's100rr-md', shipCode: 'UPS', isGlass: 1, qty: 1, weight: 2, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:item2) { double('item', ref01: 's100g-lg', shipCode: 'UPS', isGlass: 1, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:destination) { {:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    describe 'boxing charges' do
      config[:add_boxing_charge] = true

      it 'returns single glass boxing charge' do
        ship = CreatePackages.new(cart_items, config, destination)
        expect(ship.calculate_boxing(0, 1, 0, 0)).to eq(config[:first_glass_box_extra_charge].to_d + config[:sm_glass_box_charge].to_d)
      end

      it 'adds large boxing charge from create packages' do
        cart_items[0] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.create_packages(cart_items)
        expect(ship.boxing).to eq(config[:lg_glass_box_charge].to_d + config[:first_glass_box_extra_charge].to_d)
      end

      it 'adds 1 large box from a small and large' do
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.create_packages(cart_items)
        expect(ship.boxing).to eq(config[:lg_glass_box_charge].to_d + config[:first_glass_box_extra_charge].to_d)
      end

      it '6 md and 12 lg goes in 2 large boxes' do
        item.stub(:qty).and_return('6')
        item2.stub(:qty).and_return('12')
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.create_packages(cart_items)
        expect(ship.boxing).to eq((config[:lg_glass_box_charge].to_d * 2)+ config[:first_glass_box_extra_charge].to_d)
      end

      it 'adds 1 small and 1 large box from a small and large with too high qty to merge' do
        item.stub(:qty).and_return(config[:lg_box2_pieces])
        cart_items[0] = item
        cart_items[1] = item2
        ship = CreatePackages.new(cart_items, config, destination)
        ship.create_packages(cart_items)
        expect(ship.boxing).to eq(config[:lg_glass_box_charge].to_d + config[:sm_glass_box_charge].to_d + config[:first_glass_box_extra_charge].to_d)
      end

     it 'has 2 large glass boxing charges for 1 special order LG and 1 regular' do
       item.stub(:backorder).and_return(22)
       item.stub(:ref01).and_return('u60-00-sht')
       cart_items[0] = item
       cart_items[1] = item2
       ship = CreatePackages.new(cart_items, config, destination)
       ship.package_runner
       expect(ship.boxing).to eq(config[:lg_glass_box_charge].to_d + config[:lg_glass_box_charge].to_d + config[:first_glass_box_extra_charge].to_d)
     end

     it 'does not add dichro box charge for -md' do
        item.stub(:backorder).and_return(0)
        item.stub(:isGlass).and_return(3)
        item.stub(:ref01).and_return('s100rr-md')
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        ship.package_runner
        expect(ship.boxing).to eq(0)
     end

     it 'adds dichro box charge for -lg' do
        item.stub(:backorder).and_return(0)
        item.stub(:isGlass).and_return(3)
        item.stub(:ref01).and_return('s100rr-lg')
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        ship.package_runner
        expect(ship.boxing).to eq(config[:dichro_box_charge].to_d)
     end

    end

    #describe 'extra charges' do
    #  xit 'charges 8.50 for extra boxing' do
    #    config[:extra_boxing] = 'sadfg 8601 abc123'
    #    config[:extra_boxing_charge] = 8.5
    #    item.stub(:ref01).and_return('8601')
    #
    #    cart_items[0] = item
    #    cart_items[1] = item2
    #    ship = CreatePackages.new(cart_items, config, destination)
    #    ship.create_packages(cart_items)
    #    expect(ship.boxing_charge).to eq(8.5)
    #  end
    #
    #  xit 'does not add extra boxing' do
    #    config[:extra_boxing] = 'sadfg 8601 abc123'
    #    config[:extra_boxing_charge] = 8.5
    #    item.stub(:ref01).and_return('601')
    #
    #    cart_items[0] = item
    #    cart_items[1] = item2
    #    ship = CreatePackages.new(cart_items, config, destination)
    #    ship.create_packages(cart_items)
    #    expect(ship.boxing_charge).to eq(0)
    #  end
    #end
  end
end

