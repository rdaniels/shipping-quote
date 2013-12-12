# require "shipping-quote/version"
require 'active_shipping'
include ActiveMerchant::Shipping

module ShippingGem
  class Shipping

    def initialize(cart_items)
      @cart_items = cart_items
      @cart_items = [] if cart_items == nil
    end


    def create_packages
      @packages = []
      @boxing_charge = 0
      @truck_only = 0

      regular_item_weight = 0
      glass_pieces = 0
      dichro_pieces = 0
      add_lead_box = 0

      # binding.pry
      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase
        @truck_only = 1 if shipCode == 'TRK'



        glass_pieces += item.qty * 2 if item.isGlass == 1 && (item.glassConverter == nil || item.glassConverter == 0)
        glass_pieces += item.qty * item.glassConverter if item.isGlass == 1 && (item.glassConverter != nil && item.glassConverter > 0)
        dichro_pieces += item.qty if item.isGlass == 3

        #if item.isGlass == nil || item.isGlass == 0 || item.isGlass == 2
        #  if shipCode == 'SHA' || shipCode == 'TRK' || (item.weight > 26 && (shipCode == 'UPS' || shipCode == ''))
        #    (1..item.qty).each { @packages << Package.new((item.weight * 16), [5, 5, 5], :units => :imperial) }
        #  else
        #    if shipCode == 'LEA'
        #      add_lead_box = 1
        #    else
        #      # backorder = -1 normal item out of stock, purchaseCode for special order (2, 20+), 999 truck item
        #      regular_item_weight += item.weight * item.qty  #if item.backorder == 0
        #    end
        #  end
        #end
      end
    end
  end
end
