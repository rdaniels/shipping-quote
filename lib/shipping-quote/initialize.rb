module ShippingQuote
  require_relative 'quotes'
  require_relative 'filter-shipping'
  require_relative 'create-packages'
  require_relative 'free-shipping'
  require_relative 'rlcarriers'
  require 'geographer'

  class States
    include Geographer::Us::States
  end

  class Shipping
    attr_accessor :boxing_charge, :notes, :packages, :remarks, :lowest_priced, :cart_items

    def initialize(cart_items, config = nil)
      @remarks = ''
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
          item.define_singleton_method(:length) { 10 } if !defined? item.length
          item.define_singleton_method(:width) { 10 } if !defined? item.width
          item.define_singleton_method(:height) { 10 } if !defined? item.height

          if item.shipCode == 'SHA' && (item.length == 0 || item.width == 0 || item.height == 0)
            item.stub(:length).and_return(10)
            item.stub(:height).and_return(10)
            item.stub(:width).and_return(10)
          end
      end
    end


    def runner(destination, ship_selected=nil, allow_free_ship=true)
      ship = CreatePackages.new(@cart_items, @config, destination, truck_only)
      packages = ship.package_runner
      @notes ||= ship.notes
      @boxing_charge = ship.boxing
      destination['province'] = 'VI' if destination['country'] == 'VI'
      destination['country'] = 'US' if destination['country'] == 'VI'
      destination['province'] = '' if destination['province'].class == FalseClass

      if destination['country'] == 'US' && destination['province'].length > 2
        destination['province'] =  States.names_abbreviation_map[destination['province'].titleize]
      end

      if destination[:country] == 'US' && destination[:province].length > 2
        destination[:province] =  States.names_abbreviation_map[destination[:province].titleize]
      end

      quote = Quote.new(@cart_items, @config, truck_only)
      quotes = quote.quotes(destination, packages, ship_selected)
      @notes ||= quote.notes if quote.notes.to_s != '' && quote.notes != []

      filter = FilterShipping.new(@cart_items,@config, truck_only)
      filtered_quotes = filter.filter_shipping(quotes, destination, ship_selected)

      if quotes.length > 0 && filtered_quotes.length == 0
        @config[:shown_rates] = @config[:po_box_rates]
        filtered_quotes = filter.filter_shipping(quotes, destination, ship_selected)
      end
      @lowest_priced = FreeShipping.lowest_priced(filtered_quotes)[0] if filtered_quotes != []

      # free shipping
      if allow_price_class(destination) == true
        free_shipping = FreeShipping.new(@cart_items,@config)
        if truck_only != 1 && free_shipping.validate_location(destination) == true && filtered_quotes != []
          ship_free = CreatePackages.new(@cart_items, @config, destination, truck_only, allow_free_ship)
          ship_free.package_runner(1)
          packages_free_removed = ship_free.packages

          if packages_free_removed.map{|p| p.weight}.sum != packages.map{|p| p.weight}.sum
            if packages_free_removed == nil || packages_free_removed.length == 0
              filtered_quotes = free_shipping.update_quote(filtered_quotes, 0, @lowest_priced)
            else
              quotes_free_removed = quote.quotes(destination, packages_free_removed, @lowest_priced)
              filtered_quotes = free_shipping.update_quote(filtered_quotes, quotes_free_removed[0][1], @lowest_priced)
            end
          end
        end
      end
      ormd_notes

      packages.each_with_index { |p,i| @remarks += "Package #{i+1} weight: #{p.weight.to_f / 16} NEWLINE " }
      @remarks += "Boxing: #{@boxing_charge} NEWLINE NEWLINE "
      @cart_items.each_with_index { |p,i| @remarks += "Item#{i+1} ref01: #{p.ref01}, qty: #{p.qty}, weight: #{p.weight}, shipCode: #{p.shipCode}, isGlass: #{p.isGlass} NEWLINE " }

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

      count_glass = 0
      @cart_items.each do |item|
        if item.isGlass.to_i == 1
          isku = item.ref01.downcase
          if isku.include?('-sm') || isku.include?('-md')
          elsif isku.include?('-lg')
            count_glass += item.qty.to_i
          else
            multiplier = 2
            multiplier = item.glassConverter.to_i if item.glassConverter.to_i > 0
            count_glass += (item.qty.to_i * multiplier)
          end
        end
      end
      return 2 if count_glass > 30

      return 0
    end


  def ormd_notes
    ormd_items = @cart_items.find_all { |item| item.ormd != nil && item.ormd.to_i > 0 }
    @notes = '' if @notes == nil
    ormd_items.each do |item|
      @notes += 'Item ' + item.ref01.to_s + ' cannot ship air.'
    end
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

