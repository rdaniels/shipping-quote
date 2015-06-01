require 'spec_helper'

module ShippingQuote
  describe PullCarriers do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }


      it 'returns fedex' do
        destination[:country] = 'CA'
        destination[:province] = 'ON'
        destination[:postal_code] = 'xxx'
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        pack = CreatePackages.new(cart_items, config, destination, ship.truck_only)
        packages = pack.package_runner

        origin = ActiveShipping::Location.new(config[:origin])
        location_destination = ActiveShipping::Location.new(destination)

        carriers = PullCarriers.new(config)
        fedex_rate = carriers.pull_fedex(origin, location_destination, packages)

        puts fedex_rate
      end



  end
end

