# ShippingQuote

Produces FedEx and USPS shipping quotes with boxing charges based on the Daniels Corporation shipping algorithm.
Generate the Gem file with: gem build example_gem.gemspec

## Installation

Update values in shipping-quote.yml and place in your RAILS_ENV/config folder.
Add this line to your application's Gemfile:

    gem 'shipping-quote'

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install shipping-quote

## Usage
    require 'shipping-quote'

    ship = Shipping.new(cart_items)
    packages = ship.create_packages
    quote = ship.quotes(destination,packages)

cart_items is and array of items
example item (all fields required) {shipCode: 'UPS', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10}
example destination { :country => 'US', :province => 'FL', :city => 'Tampa', :postal_code => '33609'}


## Development

For development, copy shipping-quote.yml to shipping-quote-spec.yml and update values. Add tests to
shipping-quote-spec.rb before adding code to shipping-quote.rb.
Pry sometimes crashes when called from Vagrant : RSpec, use run-shipping-quote for pry debugging instead



## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create new Pull Request
