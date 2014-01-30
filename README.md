# ShippingQuote

[![GitHub version](https://badge.fury.io/gh/rdaniels%2Fshipping-quote.png)] (http://badge.fury.io/gh/rdaniels%2Fshipping-quote)
[![Dependency Status](https://gemnasium.com/rdaniels/shipping-quote.png)] (https://gemnasium.com/rdaniels/shipping-quote)
[![Code Climate](https://codeclimate.com/repos/52b43de1f3ea0062e702eb2a/badges/bf8295c990fc324c25b1/gpa.png)](https://codeclimate.com/repos/52b43de1f3ea0062e702eb2a/feed)


ShippingQuote breaks computes how many packages are needed to ship the contents of a user's shopping cart based on Item Weight,
Ship Code, and a set Max Box Weight. ShipQuote then will push send these packages to FedEx and USPS to give a final shipping quote for
the entire cart.

## Installation

Update values in shipping-quote.yml and place in your RAILS_ENV/config folder.
Add this line to your application's Gemfile:

    gem 'shipping-quote', :github => 'rdaniels/shipping-quote'

And then execute:

    $ bundle


## Usage
    require 'shipping-quote'

    ship = ShippingQuote::Shipping.new(@cart_items)
    @shown_rates = ship.runner(@c)  #@c = ship_to
    @boxing_charge = ship.boxing_charge

runner also takes an optional ship_selected argument, used to filter on repull

cart_items is an array of items

example item

    {   ref01: '3000',
        name: 'Super Widget'
        shipCode: 'UPS',
        isGlass: nil,
        qty: 1,
        weight: 1,
        backorder: 0,
        vendor: 10,
        ormd: nil,
        glassConverter: nil,
        freeShipEligable: nil }

example ship_to

    {   :country => 'US',
        :street => '1234 fake street',
        :street2 => nil,
        :province => 'FL',
        :city => 'Tampa',
        :postal_code => '33609'}


## Shipping Rules

backordered items are grouped together and quoted as 1 box per vendor

optional extra 'boxing charges' for select items

all FedEx quotes removed if customer has PO Box in destination street or street 2

all air options removed if any item has ormd = 1 (hazardous material)



## RSpec Passed Tests

    $ sudo rspec spec/*

    ShippingQuote::Shipping
      boxing charges
        returns single glass boxing charge
        adds boxing charge from create packages
      create packages
        single UPS item under box max weight returns 1 package
        nil returns no packages
        4 UPS items under box max weight returns 1 package
        1 special order item + 1 UPS item under box max weight returns 2 packages
        returns missing item weight in note and no packages
        nil allowed in vendor and shipCode for special order item
        2 special order items + 1 UPS item under box max weight returns 2 packages
        3 UPS items over box max weight returns 2 packages
        2 UPS items over box max weight returns 2 packages
        random number of lead items returns 1 package
        SHA item returns 1 package

    ShippingQuote::Shipping
      filter shipping
        returns fedex express saver, home ground, and usps standard
        only returns ground when ormd
        returns multiple quotes for Canada
        returns truck option only if item has shipCode = TRK
      truck only
        UPS item returns truck_only as 0
        TRK item returns truck_only as 1
      quotes
        returns fedex express saver, home ground, and usps standard
        quote to FL less than quote to California
        quote without boxing code less than quote with boxing charge

    ShippingQuote::Shipping
      runner
        removes all fedex if po.box address
        returns missing item weight in note and no packages
        filters if ship_selected


## Development

For development, copy shipping-quote.yml to shipping-quote-spec.yml and update values. Add tests to
shipping-quote-spec.rb before adding code to shipping-quote.rb.



