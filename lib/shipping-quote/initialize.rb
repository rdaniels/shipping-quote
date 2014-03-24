#require 'pry'

module ShippingQuote
  require_relative 'quotes'
  require_relative 'filter-shipping'
  require_relative 'create-packages'
  require_relative 'free-shipping'
  require_relative 'rlcarriers'


  class Shipping
    attr_accessor :boxing_charge, :notes, :packages

    def initialize(cart_items, config = nil)
      @cart_items = cart_items
      @cart_items = [] if cart_items == nil
      @config = config

      @config = YAML::load(IO.read("#{Rails.root}/config/shipping-quote.yml")) if @config == nil

      #begin
      #  @config = YAML::load(IO.read("#{Rails.root}/config/shipping-quote.yml")) if @config == nil
      #rescue
      #  log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
      #end

      @cart_items.each do |item|
          item.define_singleton_method(:ref01) { nil } if !defined? item.ref01
          item.define_singleton_method(:name) { nil } if !defined? item.name
          item.define_singleton_method(:shipCode) { nil } if !defined? item.shipCode
          item.define_singleton_method(:isGlass) { nil } if !defined? item.isGlass
          item.define_singleton_method(:qty) { 1 } if !defined? item.qty
          item.define_singleton_method(:weight) { nil } if !defined? item.weight
          item.define_singleton_method(:backorder) { nil } if !defined? item.backorder
          item.define_singleton_method(:vendor) { nil } if !defined? item.vendor
          item.define_singleton_method(:ormd) { nil } if !defined? item.ormd
          item.define_singleton_method(:glassConverter) { nil } if !defined? item.glassConverter
          item.define_singleton_method(:freeShipping) { nil } if !defined? item.freeShipping
      end
    end


    def runner(destination, ship_selected=nil, allow_free_ship=true)
      ship = CreatePackages.new(@cart_items, @config, destination, truck_only)
      packages = ship.package_runner
      @notes = ship.notes
      @boxing_charge = ship.boxing
      quote = Quote.new(@cart_items, @config, truck_only)
      quotes = quote.quotes(destination, packages, ship_selected)
      filter = FilterShipping.new(@cart_items,@config, truck_only)
      filtered_quotes = filter.filter_shipping(quotes, destination, ship_selected)

      # free shipping
      if allow_free_ship == true && allow_price_class(destination) == true
        free_shipping = FreeShipping.new(@cart_items,@config)
        if truck_only == 0 && free_shipping.validate_location(destination) == true && filtered_quotes != []
          lowest_priced = FreeShipping.lowest_priced(filtered_quotes)[0]
          ship_free = CreatePackages.new(@cart_items, @config, destination, truck_only)
          ship_free.package_runner(1)
          packages_free_removed = ship_free.packages

          if packages_free_removed.map{|p| p.weight}.sum != packages.map{|p| p.weight}.sum
            if packages_free_removed == nil || packages_free_removed.length == 0
              filtered_quotes = free_shipping.update_quote(filtered_quotes, 0, lowest_priced)
            else
              quotes_free_removed = quote.quotes(destination, packages_free_removed, lowest_priced)
              filtered_quotes = free_shipping.update_quote(filtered_quotes, quotes_free_removed[0][1], lowest_priced)
            end
          end
        end
      end
      quote.multiplier(filtered_quotes)
    end


    def allow_price_class(destination)
      price_class = destination[:price_class].to_s
      return true if price_class == ''
      return true if price_class == 'nil'
      return true if @config[:free_shipping][:excluded_price_class] == nil
      return true if @config[:free_shipping][:excluded_price_class] == 'nil'
      return true if @config[:free_shipping][:excluded_price_class] == ''

      !@config[:free_shipping][:excluded_price_class].split(',').include?(price_class)
    end

    def truck_only
      @cart_items.each do |item|
        item.shipCode == nil ? shipCode = '' : shipCode = item.shipCode.upcase
        return 1 if shipCode == 'TRK'
      end
      return 0
    end
  end


end


class ::Hash
  def method_missing(name, *args, &blk)
    if args.empty? && blk.nil? #&& @attributes.has_key?(name)
      #@attributes[name]
      self["#{name.to_s}"]
      self[name]
    else
      super
    end
  end
end

