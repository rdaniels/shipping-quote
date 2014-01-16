require 'pry'
class FreeShipping

  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
  end

  def validate_date
    pass = true
    start_date = @config[:free_shipping][:start_date]
    end_date = @config[:free_shipping][:end_date]
    start_date = Date.parse(start_date) if start_date.class == String && start_date != 'nil'
    end_date = Date.parse(end_date) if end_date.class == String && end_date != 'nil'

    pass = false if start_date == nil
    pass = false if end_date == nil
    pass = false if start_date == 'nil'
    pass = false if end_date == 'nil'
    if pass == true
      pass = false if start_date > Date.today
      pass = false if end_date < Date.today
    end
    pass
  end

  def validate_location(destination)
    pass = true
    pass = false if destination[:country] != 'US'
    pass = false if %w[AP AE AK HI PR VI].include? destination[:state]
    pass
  end

  #TODO: eligable items with priceClass minimums

end
