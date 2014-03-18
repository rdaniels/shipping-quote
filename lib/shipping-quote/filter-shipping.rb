# require 'pry'

class FilterShipping
  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
  end


  def filter_shipping(quotes, destination, ship_selected=nil)
    shown_rates = []
    count_glass = pull_glass_count

    if count_glass > 18 || @truck_only == 1
      quotes.delete_if { |a| !a.to_s.match(/Truck Shipping/) }
      return quotes
    else

      if ship_selected != nil && ship_selected == 'FedEx Ground'
        quotes.delete_if { |a| !a.to_s.match(/FedEx Ground/) }
      elsif ship_selected != nil
        quotes.delete_if { |a| !a.to_s.match(/#{ship_selected}/) }
      end
      quotes.delete_if { |a| a.to_s.match(/USPS Media Mail/) } if allow_media_mail == false
      quotes.delete_if { |a| a.to_s.match(/USPS First-Class Mail Parcel/) } if allow_first_class == false
      quotes.each do |q|
        shown_rates << q if @config[:shown_rates].include? q[0]
      end

      # replace FedEx Ground Home with just FedEx Ground
      shown_rates.collect! { |rate| (rate[0] == 'FedEx Ground Home Delivery') ? ['FedEx Ground', rate[1]] : rate }
      # remove the 1-Day, 2-Day, etc.
      shown_rates.collect! { |rate| (rate[0].include?('-Day')) ? [rate[0].gsub(/[0-9]/,'').gsub(' -Day',''), rate[1]] : rate }

      is_po_box = 0
      is_po_box = 1 if destination[:street] != nil && ['p.o', 'po box', 'p o box'].any? { |w| destination[:street].to_s.downcase =~ /#{w}/ }
      is_po_box = 1 if destination[:street2] != nil && ['p.o', 'po box', 'p o box'].any? { |w| destination[:street2].to_s.downcase =~ /#{w}/ }

      shown_rates.delete_if { |rate| rate[0][0..4] == 'FedEx' } if is_po_box == 1

      ormd = check_ormd
      shown_rates = shown_rates.delete_if { |rate| rate[0] != 'FedEx Ground' && rate[0] != 'FedEx Ground Home Delivery' } if ormd > 0
      shown_rates
    end
  end

  def allow_media_mail
    pass = false
    media_items = @cart_items.find_all { |item| item.shipCode != nil && item.shipCode.downcase == 'mda' }
    npa_items = @cart_items.find_all { |item| item.shipCode != nil && item.shipCode.downcase == 'npa' }
    pass = true if media_items.length == @cart_items.length
    pass
  end

  def allow_first_class
    weight = 0
    @cart_items.each { |item| weight += item.weight.to_d * item.qty.to_i if item.weight != nil }
    npa_items = @cart_items.find_all { |item| item.shipCode != nil && item.shipCode.downcase == 'npa' }
    return false if weight > @config[:first_class_weight_limit].to_d || npa_items.length > 0
    true
  end

  def check_ormd
    ormd_items = @cart_items.find_all { |item| item.ormd != nil && item.ormd.to_i > 0 }
    ormd_items.length
  end

  def pull_glass_count
    count_glass = 0
    @cart_items.each do |item|
      if item.isGlass == 1
        multiplier = 2
        multiplier = item.glassConverter.to_i if item.glassConverter != nil && item.glassConverter.to_i > 0
        count_glass += (item.qty * multiplier)
      end
    end
    count_glass
  end
end
