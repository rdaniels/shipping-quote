class FreeShipping

  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
  end

  def update_quote(quotes, new_price, shipping_method='FedEx Ground')
    shown_rates = []
    quotes.each {|q| q[0] == shipping_method ? shown_rates << [q[0], new_price] : shown_rates << q}
    shown_rates
  end


  def free_ship_ok(free_ship, destination)
    return false if free_ship.to_i == 0
    return false if validate_location(destination) == false
    return false if validate_date == false && free_ship.to_i == 1
    return true if validate_date == true && free_ship.to_i == 1
    return true if free_ship.to_i == 2 || free_ship.to_i == 3
    false
  end


  def self.lowest_priced(quotes)
    lowest_shipping = quotes[0]
    quotes.each do |q|
      lowest_shipping = q if q[1] < lowest_shipping[1]
    end
    lowest_shipping
  end


  def validate_date
    pass = true
    start_date = @config[:free_shipping][:start_date]
    end_date = @config[:free_shipping][:end_date]

    start_date = Date.parse(start_date) if start_date.class == String && start_date != 'nil'
    end_date = Date.parse(end_date) if end_date.class == String && end_date != 'nil'

    start_date = Date.today << 1 if start_date == nil || start_date == 'nil'
    end_date = Date.today >> 1 if end_date == nil || end_date == 'nil'

    if pass == true
      pass = false if start_date > Date.today
      pass = false if end_date < Date.today
    end
    pass
  end


  def validate_location(destination)
    pass = true
    pass = false if destination[:country] != 'US'
    pass = false if %w[AP AE AK HI PR VI].include? destination[:province]
    pass
  end

  #TODO: eligable items with priceClass minimums
  #TODO: pass in free shipping eligability with @cart_items items

end
