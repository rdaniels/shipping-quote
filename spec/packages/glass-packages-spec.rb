require 'spec_helper'

module ShippingQuote
  config = YAML::load(IO.read("./shipping-quote-delphi.yml"))


  describe CreatePackages do
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: 's100-lg', shipCode: 'UPS', isGlass: 1, qty: 1, weight: 2, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: 1, qty: 1, weight: 10, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }

    config[:lg_box_pieces] = 4
    config[:lg_box2_pieces] = 9
    config[:sm_box_pieces] = 12
    config[:sm_box2_pieces] = 24
    config[:dichro_box_charge] = 2.5
    config[:lg_glass_box_charge] = 8.95

    describe 'dichro' do
      it 'calculates dichro sizes as normal UPS items + dichro boxing' do
        item.stub(:isGlass).and_return(3)
        item2.stub(:isGlass).and_return(0)
        cart_items[0] = item
        cart_items[1] = item
        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(1).package
        expect(ship.boxing).to eq(config[:dichro_box_charge])
      end

      it 'calculates dichro sht as large glass' do
        item.stub(:ref01).and_return('x100-sht')
        item.stub(:isGlass).and_return(3)
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(1).package
        expect(ship.boxing).to eq(config[:lg_glass_box_charge])
      end

      it 'returns missing item weight in note and no packages' do
        item.stub(:weight).and_return(nil)
        item.stub(:isGlass).and_return(3)
        item2.stub(:isGlass).and_return(0)
        cart_items[0] = item
        cart_items[1] = item
        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(0).packages
        expect(ship.notes).to eq('Item s100-lg is missing weight.')
      end

    end



    describe 'large glass packages' do

      it 'returns 1 large glass box' do
        item2.stub(:ref01).and_return('s100gg-sht')
        cart_items[0] = item
        cart_items[1] = item2

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(1).package
      end

      it 'returns 1 large and large2 glass box' do
        item.stub(:qty).and_return(10)
        item2.stub(:ref01).and_return('s100gg-lg')
        item2.stub(:qty).and_return(2)
        cart_items[0] = item
        cart_items[1] = item2

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(2).packages
      end

      it 'returns 3 large2 glass boxes + 1 reg box' do
        item.stub(:qty).and_return(27)
        item2.stub(:qty).and_return(1)
        item2.stub(:isGlass).and_return(0)
        cart_items[0] = item
        cart_items[1] = item2

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(4).packages
      end
    end


    describe 'small glass packages' do
      it 'returns no small or small2 glass box' do
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config)
        expect(ship.small_glass_packages(0)).to eq([0,0])
      end

      it 'returns 1 small glass box' do
        item.stub(:ref01).and_return('s100-md')
        item2.stub(:ref01).and_return('s100gg-md')
        cart_items[0] = item
        cart_items[1] = item2

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(1).packages
      end

      it 'returns 1 small and small2 glass box' do
        item.stub(:ref01).and_return('s100-md')
        item.stub(:qty).and_return(15)
        item2.stub(:ref01).and_return('s100gg-md')
        item2.stub(:qty).and_return(16)
        cart_items[0] = item
        cart_items[1] = item2

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(2).packages
      end

      it 'returns 3 small2 glass boxes' do
        item.stub(:ref01).and_return('s100-md')
        item.stub(:qty).and_return(72)
        cart_items[0] = item

        ship = CreatePackages.new(cart_items, config)
        expect(ship.small_glass_packages(72)).to eq([0,3])
      end
      it 'returns 3 small2 glass packages' do
        item.stub(:ref01).and_return('s100-md')
        item.stub(:qty).and_return(72)
        cart_items[0] = item

        ship = CreatePackages.new(cart_items, config)
        expect(ship.create_packages(cart_items)).to have(3).packages
      end
    end

  end
end

