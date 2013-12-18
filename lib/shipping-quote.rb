# require "shipping-quote/version"
require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping
#require 'yaml'

module ShippingQuote

  class Shipping
    attr_accessor :boxing_charge, :config, :notes

    def initialize(cart_items, config = nil)
      @cart_items = cart_items
      @cart_items = [] if cart_items == nil
      @config = config

      begin
        @config = YAML::load(IO.read("#{RAILS_ENV}/config/shipping-quote.yml")) if @config == nil
      rescue
        #log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
      end

    end


    def calculate_boxing (add_lead_box, glass_boxes, dichro_boxes, truck_only = 0)
      boxing_charge = 0

      if glass_boxes > 6 || truck_only == 1
        boxing_charge = 0

      elsif @config[:add_boxing_charge] == true
        boxing_charge += @config[:lead_box_charge] if add_lead_box == 1
        boxing_charge += @config[:first_glass_box_extra_charge] if glass_boxes > 0 # $15 for first glass box, $8 each additional
        boxing_charge += (glass_boxes * @config[:sm_glass_box_charge])
        boxing_charge += (dichro_boxes * @config[:dichro_box_charge])
      end
      boxing_charge
    end


    def create_packages()
      @packages = []
      regular_item_weight = 0
      glass_pieces = 0
      dichro_pieces = 0
      add_lead_box = 0

      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase

        glass_pieces += item.qty * 2 if item.isGlass == 1 && (item.glassConverter == nil || item.glassConverter == 0)
        glass_pieces += item.qty * item.glassConverter if item.isGlass == 1 && (item.glassConverter != nil && item.glassConverter > 0)
        dichro_pieces += item.qty if item.isGlass == 3

        if item.isGlass == nil || item.isGlass == 0 || item.isGlass == 2
          if shipCode == 'SHA' || shipCode == 'TRK' || (item.weight > @config[:box_max_weight] && (shipCode == 'UPS' || shipCode == ''))
            (1..item.qty).each { @packages << Package.new((item.weight * 16), [5, 5, 5], :units => :imperial) }
          else
            if shipCode == 'LEA'
              add_lead_box = 1
            else
              # backorder = -1 normal item out of stock, purchaseCode for special order (2, 20+), 999 truck item
              regular_item_weight += item.weight * item.qty  #if item.backorder == 0
            end
          end
        end
      end

      # regular items
      full_item_boxes = (regular_item_weight.to_f / @config[:box_max_weight]).to_i
      (1..full_item_boxes).each { @packages << Package.new((@config[:box_max_weight] * 16), [5, 5, 5], :units => :imperial) }
      partial_item_box = regular_item_weight - (full_item_boxes * @config[:box_max_weight])
      @packages << Package.new((partial_item_box * 16), [5, 5, 5], :units => :imperial) if partial_item_box > 0

      # lead8
      @packages << Package.new((@config[:box_lead_weight] * 16), [5, 5, 5], :units => :imperial) if add_lead_box == 1

      # special order
      full_vendor_boxes = 0
      special_order = @cart_items.select { |item| (item.shipCode == 'UPS' || item.shipCode == '' || item.shipCode == nil) && (item.backorder == 2 || (item.backorder >= 20 && item.backorder < 300)) }
      special_order.group_by { |item| item.vendor }.each do |s|
        box_weight = 0
        s[1].each { |i| box_weight += i.weight }
        full_vendor_boxes += (box_weight / @config[:box_max_weight]).to_i
        partial_vendor_box = box_weight - full_vendor_boxes
        @packages << Package.new((partial_vendor_box * 16), [5, 5, 5], :units => :imperial) if partial_vendor_box > 0
      end
      (1..full_vendor_boxes).each { @packages << Package.new((@config[:box_max_weight] * 16), [5, 5, 5], :units => :imperial) }

      @packages
    end


    def filter_shipping(quotes, street=nil, street2=nil, truck_only=0, ship_selected=nil )
      count_glass = 0
      shown_rates = []
      @cart_items.each do |item|
        if item.isGlass == 1
          multiplier = 2
          multiplier = item.glassConverter if item.glassConverter != nil && item.glassConverter > 0
          count_glass += (item.qty * multiplier)
        end
      end


      if count_glass > 18 || truck_only == 1
        shown_rates << ['Truck Shipping', 0]
      else

        if ship_selected != nil && ship_selected == 'FedEx Ground'
          quotes.delete_if { |a| !a.to_s.match(/FedEx Ground/) }
        elsif ship_selected != nil
          quotes.delete_if { |a| !a.to_s.match(/#{ship_selected}/) }
        end

        quotes.each do |q|
          shown_rates << q if config[:shown_rates].include? q[0]
        end

        # replace FedEx Ground Home with just FedEx Ground
        shown_rates.collect! { |rate| (rate[0] == 'FedEx Ground Home Delivery') ? ['FedEx Ground', rate[1]] : rate }

        is_po_box = 0
        is_po_box = 1 if street != nil && ['p.o', 'po box', 'p o box'].any? { |w| street.to_s.downcase =~ /#{w}/ }
        is_po_box = 1 if street2 != nil && ['p.o', 'po box', 'p o box'].any? { |w| street2.to_s.downcase =~ /#{w}/ }
        shown_rates.delete_if { |rate| rate[0][0..4] == 'FedEx' } if is_po_box == 1

        # mode 1 = FedEx, mode 2 = USPS, mode 3 = both
        #mode = 2 if %w(ae ap aa dp fp).include? c.state.downcase
        #mode = 3 if mode == nil && (c.country.downcase == 'canada' or %w(ak hi pr vi).include? c.state.downcase)
        #mode = 1 if mode == nil && c.country.downcase == 'united states'
        #mode = 2 if mode == nil

        #skip_states = %w{ap ae ak hi pr vi}
        #@cart_items.each { |item| no_usps = 1 if item.weight > 70 && skip_states.include?(c.state.downcase) }

        ormd = 0
        @cart_items.each { |item| ormd = 1 if item.ormd != nil && item.ormd > 0 }
        shown_rates = shown_rates.delete_if { |rate| rate[0] != 'FedEx Ground' && rate[0] != 'FedEx Ground Home Delivery' } if ormd == 1
        shown_rates

      end
    end

    def quotes(destination, packages)
      fedex = FedEx.new(login: config[:fedex][:login], password: config[:fedex][:password],
                        key: config[:fedex][:key], account: config[:fedex][:account], meter: config[:fedex][:meter])
      origin = Location.new(config[:origin])
      location_destination = Location.new(destination)
      begin
        response = fedex.find_rates(origin, location_destination, packages)
        fedex_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
      rescue => error
        fedex_rates = []
        @notes << 'FedEx ' + error.response.message
      end

      usps = USPS.new(login: config[:usps][:login])
      begin
        response = usps.find_rates(origin, location_destination, packages)
        usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
      rescue => error
        usps_rates = []
        @notes << 'USPS ' + error.response.message
      end

      all_rates = fedex_rates + usps_rates
      all_rates.each { |line| line[1] = (line[1] * config[:rate_multiplier].to_f).round(0) }
      all_rates
    end


    def truck_only
      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase
          return 1 if shipCode == 'TRK'
      end
      return 0
    end



  end
end
