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

    ship = Shipping.new(cart_items)
    quotes = ship.runner(destination)


cart_items is and array of items

example item (all fields required) `{ shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil}`

example destination `{ :country => 'US', :street => '1234 fake street', :street2 => nil, :province => 'FL', :city => 'Tampa', :postal_code => '33609'}`

backordered items are grouped together and quoted as 1 box per vendor

optional extra 'boxing charges' for select items

all FedEx quotes removed if customer has PO Box in destination street or street 2

all air options removed if any item has ormd = 1 (hazardous material)



## Development

For development, copy shipping-quote.yml to shipping-quote-spec.yml and update values. Add tests to
shipping-quote-spec.rb before adding code to shipping-quote.rb.



