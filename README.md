# ShippingQuote

[![GitHub version](https://badge.fury.io/gh/rdaniels%2Fshipping-quote.png)] (http://badge.fury.io/gh/rdaniels%2Fshipping-quote)
[![Dependency Status](https://gemnasium.com/rdaniels/shipping-quote.png)] (https://gemnasium.com/rdaniels/shipping-quote)
[![Code Climate](https://codeclimate.com/repos/52b43de1f3ea0062e702eb2a/badges/bf8295c990fc324c25b1/gpa.png)](https://codeclimate.com/repos/52b43de1f3ea0062e702eb2a/feed)

[GitHub Website](http://rdaniels.github.io/shipping-quote)

ShippingQuote breaks computes how many packages are needed to ship the contents of a user's shopping cart based on Item
Weight, Ship Code, and a set Max Box Weight. ShipQuote then will push send these packages to UPS, FedEx, USPS, and R&L
Freight to give a final shipping quote for the entire cart. Quotes are returned as the discounted negotiated rate
(linked to the username, password).

* Creates Packages from Cart_Items
* Sends to ActiveShipping & R&L Carriers for Quotes
* Filters returned quotes


## Installation

Update values in shipping-quote.yml and place in your RAILS_ENV/config folder.
Add this line to your application's Gemfile:

    gem 'shipping-quote', :github => 'rdaniels/shipping-quote'

And then execute:

    $ bundle


## Usage
    require 'shipping-quote'

    ship = ShippingQuote::Shipping.new(@cart_items)
    shown_rates = ship.runner(destination)
    boxing_charge = ship.boxing_charge


runner also takes an optional ship_selected argument, this will only return that ship method

cart_items is an array of items

example item

    {   ref01: '3000',
        name: 'Super Widget'
        shipCode: 'UPS',
        isGlass: nil,
        qty: 1,
        weight: 0.4,
        backorder: 0,
        vendor: 10,
        ormd: nil,
        glassConverter: nil,
        freeShipping: nil }

example destination

    {   :country => 'US',
        :street => '1234 fake street',
        :street2 => nil,
        :province => 'FL',
        :city => 'Tampa',
        :postal_code => '33609'
        :price_class => 1 }


## Shipping Rules

backordered and special order items are seperated into their own packages

'boxing charges' calcualted for glass items and LEA boxing

all FedEx quotes removed if customer has PO Box in destination street or street 2

all air options removed if any item has ormd = 1 (hazardous material)

available shipCodes include: UPS, SHA, LEA, TRK, MDA, NPA

freeShipping: 1 = eligable if min reached, 2 = always free, 3 = daily deal




## Development

For development, copy shipping-quote.yml to shipping-quote-spec.yml and update values. Add tests to
shipping-quote-spec.rb before adding code to shipping-quote.rb.




