# require "shipping-quote/version"
require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping
#require 'yaml'

module ShippingQuote

  class Shipping
    attr_accessor :boxing_charge, :config

    def initialize(cart_items, config = nil)

      @cart_items = cart_items
      @cart_items = [] if cart_items == nil
      config == nil ? @config = { box_max_weight: 25,
                  box_lead_weight: 31,
                  add_boxing_charge: false,
                  lead_box_charge: 5,
                  sm_glass_box_charge: 8,
                  lg_glass_box_charge: 8,
                  dichro_box_charge: 5,
                  first_glass_box_extra_charge: 7 } : @config = config

      begin
        @config = YAML::load(IO.read("#{RAILS_ENV}/config/shipping-quote.yml"))
      rescue
        #log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
      end
    end


    def create_packages()
      @packages = []

      regular_item_weight = 0
      glass_pieces = 0
      dichro_pieces = 0
      add_lead_box = 0

      #binding.pry
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

      # lead
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


    def truck_only
      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase
          return 1 if shipCode == 'TRK'
      end
      return 0
    end

    def calculate_boxing (add_lead_box, glass_boxes, dichro_boxes)
      boxing_charge = 0
       if @config[:add_boxing_charge] == true
        boxing_charge += @config[:lead_box_charge] if add_lead_box == 1
        boxing_charge += @config[:first_glass_box_extra_charge] if glass_boxes > 0 # $15 for first glass box, $8 each additional
        boxing_charge += (glass_boxes * @config[:sm_glass_box_charge])
        boxing_charge += (dichro_boxes * @config[:dichro_box_charge])
      end
      boxing_charge
    end

  end
end
