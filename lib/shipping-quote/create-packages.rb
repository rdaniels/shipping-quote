class CreatePackages
  attr_accessor :boxing

  def initialize(cart_items, config, truck_only)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
  end


  def calculate_boxing (add_lead_box, glass_boxes, dichro_boxes)
    boxing_charge = 0

    if glass_boxes > 6 || @truck_only == 1
      boxing_charge = 0

    elsif @config[:add_boxing_charge] == true
      boxing_charge += @config[:lead_box_charge] if add_lead_box == 1
      boxing_charge += @config[:first_glass_box_extra_charge] if glass_boxes > 0 # $15 for first glass box, $8 each additional
      boxing_charge += (glass_boxes * @config[:sm_glass_box_charge])
      boxing_charge += (dichro_boxes * @config[:dichro_box_charge])
    end
    boxing_charge
  end


  def create_packages
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
            regular_item_weight += item.weight * item.qty #if item.backorder == 0
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


    # glass
    glass_boxes = (glass_pieces.to_f / 6).ceil
    if glass_pieces > 0
      glass_box_weight = 48
      (1..glass_boxes).each { @packages << Package.new((glass_box_weight * 16), [5, 5, 5], :units => :imperial) }
    end

    # dichro
    dichro_boxes = (dichro_pieces.to_f / 6).ceil
    if dichro_pieces > 0
      glass_box_weight = ((dichro_pieces * 3) / dichro_boxes) + 4
      (1..dichro_boxes).each { @packages << Package.new((glass_box_weight * 16), [5, 5, 5], :units => :imperial) }
    end

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

    @boxing = calculate_boxing(add_lead_box, glass_boxes, dichro_boxes)
    @packages
  end



end
