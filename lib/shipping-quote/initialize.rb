module ShippingQuote
  #require './lib/shipping-quote/free-shipping'
  require_relative 'free-shipping'

  class Shipping
    attr_accessor :boxing_charge, :notes

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
        item.define_singleton_method(:shipCode) { nil } if !defined? item.shipCode
        item.define_singleton_method(:isGlass) { nil } if !defined? item.isGlass
        item.define_singleton_method(:qty) { 1 } if !defined? item.qty
        item.define_singleton_method(:weight) { nil } if !defined? item.weight
        item.define_singleton_method(:backorder) { nil } if !defined? item.backorder
        item.define_singleton_method(:vendor) { nil } if !defined? item.vendor
        item.define_singleton_method(:ormd) { nil } if !defined? item.ormd
        item.define_singleton_method(:glassConverter) { nil } if !defined? item.glassConverter
      end
    end



    def calculate_boxing(add_lead_box, glass_boxes, dichro_boxes)
      cp = CreatePackages.new(@cart_items, @config, truck_only)
      cp.calculate_boxing(add_lead_box, glass_boxes, dichro_boxes)
    end

    def create_packages
      cp = CreatePackages.new(@cart_items, @config, truck_only)
      cp.create_packages
      @boxing_charge = cp.boxing
      @notes = cp.notes
      cp.create_packages
    end

    def filter_shipping(quotes, destination, ship_selected=nil)
      quote = Quote.new(@cart_items, @config, truck_only)
      quote.filter_shipping(quotes, destination, ship_selected)
    end

    def quotes(destination, packages)
      quote = Quote.new(@cart_items, @config, truck_only)
      quote.quotes(destination, packages)
    end

    def runner(destination, ship_selected=nil)
      packages = create_packages
      quotes = quotes(destination, packages)
      filter_shipping(quotes, destination, ship_selected)
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