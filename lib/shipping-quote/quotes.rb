require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping

class Quote
  attr_accessor :notes


  def initialize(cart_items, config, truck_only)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
  end


  def pull_glass_count
    count_glass = 0
    @cart_items.each do |item|
      if item.isGlass == 1
        multiplier = 2
        multiplier = item.glassConverter if item.glassConverter != nil && item.glassConverter > 0
        count_glass += (item.qty * multiplier)
      end
    end
    count_glass
  end


  def filter_shipping(quotes, destination, ship_selected=nil )
    shown_rates = []
    count_glass = pull_glass_count

    if count_glass > 18 || @truck_only == 1
      shown_rates << ['Truck Shipping', 0]
    else

      if ship_selected != nil && ship_selected == 'FedEx Ground'
        quotes.delete_if { |a| !a.to_s.match(/FedEx Ground/) }
      elsif ship_selected != nil
        quotes.delete_if { |a| !a.to_s.match(/#{ship_selected}/) }
      end

      quotes.each do |q|
        shown_rates << q if @config[:shown_rates].include? q[0]
      end

      # replace FedEx Ground Home with just FedEx Ground
      shown_rates.collect! { |rate| (rate[0] == 'FedEx Ground Home Delivery') ? ['FedEx Ground', rate[1]] : rate }

      is_po_box = 0
      is_po_box = 1 if destination[:street] != nil && ['p.o', 'po box', 'p o box'].any? { |w| destination[:street].to_s.downcase =~ /#{w}/ }
      is_po_box = 1 if destination[:street2] != nil && ['p.o', 'po box', 'p o box'].any? { |w| destination[:street2].to_s.downcase =~ /#{w}/ }
      shown_rates.delete_if { |rate| rate[0][0..4] == 'FedEx' } if is_po_box == 1

      # mode 1 = FedEx, mode 2 = USPS, mode 3 = both
      #mode = 2 if %w(ae ap aa dp fp).include? c.state.downcase
      #mode = 3 if mode == nil && (c.country.downcase == 'canada' or %w(ak hi pr vi).include? c.state.downcase)
      #mode = 1 if mode == nil && c.country.downcase == 'united states'
      #mode = 2 if mode == nil

      #skip_states = %w{ap ae ak hi pr vi}
      #@cart_items.each { |item| no_usps = 1 if item.weight > 70 && skip_states.include?(c.state.downcase) }

      ormd = check_ormd
      shown_rates = shown_rates.delete_if { |rate| rate[0] != 'FedEx Ground' && rate[0] != 'FedEx Ground Home Delivery' } if ormd > 0
      shown_rates

    end
  end

  def check_ormd
    ormd_items = @cart_items
      .find_all { |item| item.ormd != nil && item.ormd > 0 }
    ormd_items.length
  end

  def quotes(destination, packages)
    origin = Location.new(@config[:origin])
    location_destination = Location.new(destination)
    fedex_rates = pull_fedex(origin, location_destination, packages)
    usps_rates = pull_usps(origin, location_destination, packages)

    all_rates = fedex_rates + usps_rates
    all_rates.each { |line| line[1] = (line[1] * @config[:rate_multiplier].to_f).round(0) }
    all_rates
  end

  def pull_fedex (origin, location_destination, packages)
    fedex = FedEx.new(login: @config[:fedex][:login], password: @config[:fedex][:password],
                      key: @config[:fedex][:key], account: @config[:fedex][:account], meter: @config[:fedex][:meter])
    begin
      response = fedex.find_rates(origin, location_destination, packages)
      fedex_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
    rescue => error
      fedex_rates = []
      @notes << 'FedEx ' + error.response.message
    end
    fedex_rates
  end


  def pull_usps (origin, location_destination, packages)
    usps = USPS.new(login: @config[:usps][:login])
    begin
      response = usps.find_rates(origin, location_destination, packages)
      usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
    rescue => error
      usps_rates = []
      @notes << 'USPS ' + error.response.message
    end
    usps_rates
  end


  def notes
    @notes
  end





end