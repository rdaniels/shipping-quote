# require 'pry'
require_relative 'filter-shipping'

class CreatePackages
  attr_accessor :boxing, :notes, :packages, :stock_items, :special_order_items

  def initialize(cart_items, config, destination, truck_only=0)
    @cart_items, @config, @destination, @truck_only = cart_items, config, destination, truck_only
    @cart_items = [] if @cart_items == nil
    @packages = []
    @boxing = 0
  end


  def package_runner(free_shipping_run=0)
    @special_order_items = @cart_items.select do |item|
      item.backorder != nil && (item.backorder.to_i == 2 || (item.backorder.to_i > 20 && item.backorder.to_i < 300))
    end
    @stock_items = @cart_items.select { |item| !special_order_items.include? item }
    create_packages(@stock_items, free_shipping_run) if @stock_items.length > 0
    create_packages(@special_order_items) if @special_order_items.length > 0
    @packages
  end



  def create_packages(cart_items, free_shipping_run=0)
    regular_item_weight = 0
    free_shipping = FreeShipping.new(cart_items,@config)
    cart_items.each do |item|
      item.shipCode == nil ? shipCode = '' : shipCode = item.shipCode.upcase

      if (free_shipping.free_ship_ok(item.freeShipping, @destination) == false || free_shipping_run == 0) && (item.isGlass == nil || item.isGlass.to_i == 0 || item.isGlass == 2 || item.isGlass == 3)

        if item.ref01.to_s[-4,4] != '-sht'  # dichro sheet added as large glass piece
          if item.weight == nil
            @notes = "Item #{item.ref01.to_s} is missing weight."
            break
          else
            if shipCode == 'SHA' || shipCode == 'TRK' || (item.weight.to_d > @config[:box_max_weight].to_d && (shipCode == 'UPS' || shipCode == ''))
              add_packages(item.qty.to_i, item.weight.to_d)
            elsif shipCode != 'LEA'
              regular_item_weight += item.weight.to_d * item.qty.to_i
            end
          end
        end
      end
    end

    # regular items
    full_item_boxes = (regular_item_weight.to_d / @config[:box_max_weight]).to_i
    add_packages(full_item_boxes, @config[:box_max_weight])
    partial_item_box = regular_item_weight - (full_item_boxes * @config[:box_max_weight])
    add_packages(1, partial_item_box) if partial_item_box > 0



    # glass boxes
    sm_pieces = 0
    lg_pieces = 0
    cart_items.each do |item|
      if item.isGlass.to_i == 1
        if item.ref01[-3,3].to_s.downcase == '-sm' || item.ref01[-3,3].to_s.downcase == '-md'
          sm_pieces += item.qty.to_i
        elsif item.ref01[-3,3].to_s.downcase == '-lg'
          lg_pieces += item.qty.to_i
        elsif defined? item.glassConverter
          lg_pieces += item.qty.to_i * 2 if item.glassConverter.to_i == 0
          lg_pieces += item.qty.to_i * item.glassConverter.to_i if item.glassConverter.to_i > 0
        else
          lg_pieces += item.qty * 2
        end
      elsif item.isGlass == 3 && !%w{-sm -md -lg}.include?(item.ref01[-3,3].to_s)
        lg_pieces += 1
      end
    end

    glass_pieces = [sm_pieces,lg_pieces]
    glass_pieces = convert_small_to_large(glass_pieces)
    small_glass_boxes = small_glass_packages(glass_pieces[0])
    large_glass_boxes = large_glass_packages(glass_pieces[1])
    add_small_glass_boxes = small_glass_boxes[0] + small_glass_boxes[1]
    add_large_glass_boxes = large_glass_boxes[0] + large_glass_boxes[1]
    lead_box = lead_packages(cart_items)
    dichro_boxes = dichro_packages(cart_items)
    #special_order

    @boxing += calculate_boxing(lead_box, add_small_glass_boxes, add_large_glass_boxes, dichro_boxes)
    @packages = [] if @notes != nil
    @packages
  end





  def convert_small_to_large(glass_pieces)
    sm_pieces = glass_pieces[0]
    lg_pieces = glass_pieces[1]
    if sm_pieces > 0 && lg_pieces > 0
      if sm_pieces + lg_pieces <= @config[:lg_box2_pieces]
        lg_pieces += sm_pieces
        sm_pieces = 0
      end
    end
    [sm_pieces,lg_pieces]
  end



  def small_glass_packages(glass_pieces)
    return [0,0] if glass_pieces == 0
    box_small = 0
    box_large = (glass_pieces.to_d / @config[:sm_box2_pieces]).floor
    remaining_pieces = glass_pieces - (box_large * @config[:sm_box2_pieces])
    if (remaining_pieces > @config[:sm_box_pieces]) then
      box_large += 1
    elsif remaining_pieces > 0
      box_small = 1
    end
    add_packages(box_small, @config[:sm_box_weight]) if box_small > 0
    add_packages(box_large, @config[:sm_box2_weight]) if box_large > 0
    return [box_small, box_large]

  end



  def large_glass_packages(glass_pieces)
    return [0,0] if glass_pieces == 0
    box_small = 0
    box_large = (glass_pieces.to_d / @config[:lg_box2_pieces]).floor
    remaining_pieces = glass_pieces - (box_large * @config[:lg_box2_pieces])
    if (remaining_pieces > @config[:lg_box_pieces]) then
      box_large += 1
    elsif remaining_pieces > 0
      box_small = 1
    end
    add_packages(box_small, @config[:lg_box_weight]) if box_small > 0
    add_packages(box_large, @config[:lg_box2_weight]) if box_large > 0
    return [box_small, box_large]
  end


  def lead_packages(cart_items)
    lead_weight = 0
    cart_items.each do |item|
      lead_weight += (item.qty * item.weight) if item.shipCode != nil && item.shipCode.upcase == 'LEA'
    end
    lead_weight = @config[:box_lead_weight] if lead_weight < @config[:box_lead_weight] && lead_weight > 0
    add_packages(1, lead_weight) if lead_weight > 0

    (lead_weight > 0) ? 1 : 0
  end


  def dichro_packages(cart_items)

    dichro_pieces = 0
    cart_items.each { |item| dichro_pieces += item.qty if item.isGlass == 3 && item.ref01[-4,4].to_s.downcase != '-sht' }
    dichro_boxes = (dichro_pieces.to_d / 6).ceil
    #if dichro_pieces > 0
    #  glass_box_weight = ((dichro_pieces * 3) / dichro_boxes) + 4
    #  add_packages(dichro_boxes, glass_box_weight)
    #end
    dichro_boxes
  end


  def calculate_boxing (add_lead_box=0, small_glass_boxes=0, large_glass_boxes=0, dichro_boxes=0)
    boxing_charge = 0
    large_glass_boxes = 0 if large_glass_boxes == nil
    small_glass_boxes = 0 if small_glass_boxes == nil

    if large_glass_boxes > 6 || @truck_only == 1
      boxing_charge = 0

    elsif @config[:add_boxing_charge] == true
      boxing_charge += @config[:lead_box_charge].to_d if add_lead_box > 0
      boxing_charge += @config[:first_glass_box_extra_charge] if small_glass_boxes > 0 || large_glass_boxes > 0 # $15 for first glass box, $8 each additional
      boxing_charge += (large_glass_boxes * @config[:lg_glass_box_charge].to_d)
      boxing_charge += (small_glass_boxes * @config[:sm_glass_box_charge].to_d)
      boxing_charge += @config[:dichro_box_charge].to_d if dichro_boxes > 0
    end

    #delphi charges $8.50 for select oversized items, from static list in config
    #@cart_items.each do |item|
    #  if @config[:extra_boxing].split(' ').include? item.ref01
    #    boxing_charge += @config[:extra_boxing_charge].to_d
    #    break
    #  end
    #end

    boxing_charge
  end

  def add_packages(qty, weight)
    (1..qty).each { @packages << Package.new((weight * 16), [5, 5, 5], :units => :imperial) }
  end

end
