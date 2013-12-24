module ShippingQuote
  class Shipping
    attr_accessor :boxing_charge

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

      #TODO: repace !defined?  for missing methods with global handler in initialize
      # @cart_items.extend(ItemMethods)
      # @cart_items.each do |item|
      #   item.merge(:shipCode => 'UPS') if !defined? item.shipCode()
      # end

    end



    def calculate_boxing(add_lead_box, glass_boxes, dichro_boxes)
      cp = CreatePackages.new(@cart_items, @config, truck_only)
      cp.calculate_boxing(add_lead_box, glass_boxes, dichro_boxes)
    end

    def create_packages
      cp = CreatePackages.new(@cart_items, @config, truck_only)
      cp.create_packages
      @boxing_charge = cp.boxing
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