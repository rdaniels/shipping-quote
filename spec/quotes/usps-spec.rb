require 'spec_helper'
#require 'pry'

module ShippingQuote
  describe Shipping do

    config = YAML::load(IO.read("./shipping-quote-delphi.yml"))
    let!(:cart_items) { [] }
    let!(:item) { double('item', ref01: '3000', shipCode: 'MDA', isGlass: nil, qty: 1, weight: 1, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:item2) { double('item', ref01: 'ab123', shipCode: 'UPS', isGlass: nil, qty: 1, weight: 20, backorder: 0, vendor: 10, ormd: nil, glassConverter: nil, freeShipping: nil) }
    let!(:destination) { {:country => 'US',:street => '1234 fake street', :province => 'FL', :city => 'Tampa', :postal_code => '33609'} }
    cart_items = []
    config[:shown_rates] += ['USPS Priority Mail 1-Day','USPS Priority Mail 2-Day','USPS Priority Mail 3-Day','USPS Priority Mail 4-Day','USPS Priority Mail 5-Day','USPS First-Class Mail Parcel']

    describe 'removes 1-Day, 2-Day, etc. messaging' do
        it 'returns USPS Priority Mail' do
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            quote = ship.runner(destination)
            has_day = quote.select{|key, value| key.to_s.match(/-Day/)}
            has_usps = quote.select{|key, value| key.to_s.match(/^USPS Priority Mail/)}
            expect(has_day.length).to eq(0)
            expect(has_usps.length).to be > 0
        end

    end

    describe 'usps shipping' do
      config[:rate_multiplier] = 1.1
      config[:media_mail_multiplier] = 1.3
      config[:first_class_weight_limit] = 0.5
      # config[:shown_rates] += ['USPS Priority Mail 1-Day','USPS Priority Mail 2-Day','USPS Priority Mail 3-Day','USPS Priority Mail 4-Day','USPS Priority Mail 5-Day','USPS First-Class Mail Parcel','USPS Media Mail']

        it 'add $1 to usps shipping' do
            config[:usps_add_charge] = 0
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            quote = ship.runner(destination)
            has_media = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        
            config[:usps_add_charge] = 1
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            quote = ship.runner(destination)
            has_media2 = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
            expect(has_media[0][1]+100).to eq(has_media2[0][1])
        end


        it 'NPA items can not ship usps first class parcel' do
            item.stub(:weight).and_return(0.1)
            item.stub(:shipCode).and_return('NPA')
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            quote = ship.runner(destination)
            has_first = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
            has_media = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
            expect(has_first.length).to eq(0)
            expect(has_media.length).to eq(0)
            expect(quote.length).to be > 0
        end

        it 'ORMD can not ship usps first class parcel or media mail' do
            item.stub(:weight).and_return(0.1)
            item.stub(:ormd).and_return(1)
            cart_items[0] = item
            ship = Shipping.new(cart_items, config)
            quote = ship.runner(destination)
            has_first = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
            has_media = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
            expect(has_first.length).to eq(0)
            expect(has_media.length).to eq(0)
            expect(quote.length).to be > 0
        end



      it '0.1 MDA weight returns first class parcel & media mail' do
        # config[:shown_rates] = ['USPS Priority Mail 1-Day','USPS Priority Mail 2-Day','USPS Priority Mail 3-Day','USPS Priority Mail 4-Day','USPS Priority Mail 5-Day','USPS First-Class Mail Parcel','USPS Media Mail']
        item.stub(:weight).and_return(0.1)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_first = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
        has_media = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}

        expect(has_first.length).to eq(1)
        expect(has_media.length).to eq(1)
      end

      it '0.6 MDA weight returns media mail but not first class' do
        item.stub(:weight).and_return(0.6)
        cart_items[0] = item
        ship = Shipping.new(cart_items, config)
        quote = ship.runner(destination)
        has_first = quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}
        has_media = quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}
        expect(has_first.length).to eq(0)
        expect(has_media.length).to eq(1)
      end

      it 'media mail multiplier applied to first class' do
        item.stub(:weight).and_return(0.1)
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        packages = ship.package_runner
        quote = Quote.new(cart_items, config)
        quotes = quote.quotes(destination, packages)
        filter = FilterShipping.new(cart_items,config)
        filtered_quotes = filter.filter_shipping(quotes, destination )
        media_before = filtered_quotes.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}[0][1].to_i
        new_quote = quote.multiplier(filtered_quotes)
        media_after = new_quote.select{|key, value| key.to_s.match(/^USPS First-Class Mail Parcel/)}[0][1].to_i
        expect(media_after).to eq(((media_before * config[:media_mail_multiplier]).to_i) + (config[:usps_add_charge] * 100))
      end

      it 'media mail multiplier applied to media mail class' do
        item.stub(:weight).and_return(0.1)
        cart_items[0] = item
        ship = CreatePackages.new(cart_items, config, destination)
        packages = ship.package_runner
        quote = Quote.new(cart_items, config)
        quotes = quote.quotes(destination, packages)
        filter = FilterShipping.new(cart_items,config)
        filtered_quotes = filter.filter_shipping(quotes, destination )
        media_before = filtered_quotes.select{|key, value| key.to_s.match(/^USPS Media Mail/)}[0][1].to_i
        new_quote = quote.multiplier(filtered_quotes)
        media_after = new_quote.select{|key, value| key.to_s.match(/^USPS Media Mail/)}[0][1].to_i
        expect(media_after).to eq(((media_before * config[:media_mail_multiplier]).to_i) + (config[:usps_add_charge] * 100))
      end
    end

    #TODO - international tests
    #https://github.com/Shopify/active_shipping/blob/master/test/remote/usps_test.rb
    #https://github.com/Shopify/active_shipping/blob/master/test/unit/carriers/usps_test.rb
    #https://github.com/Shopify/active_shipping/tree/master/test/fixtures/xml/usps

  end
end

