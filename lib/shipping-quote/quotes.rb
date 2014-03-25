require 'active_shipping'
include ActiveMerchant::Shipping
require_relative 'carriers'


class Quote
  attr_accessor :notes


  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
  end


  def po_box(destination)
    po_match = ['p.o','po box','p o box']
    street = destination[:street]
    street2 = destination[:street2]
    return true if street != nil && po_match.any? {|word| street.to_s.downcase.include?(word)}
    return true if street2 != nil && po_match.any? {|word| street2.to_s.downcase.include?(word)}
    false
  end


  def quotes(destination, packages, ship_selected=nil)
    all_rates = []
    c = PullCarriers.new(@config)
    origin = Location.new(@config[:origin])
    destination[:country] = 'US' if ['United States','USA'].include? destination[:country]
    destination[:country] = 'CA' if ['Canada'].include? destination[:country]
    location_destination = Location.new(destination)

    country_key = %w(USPS FedEx)
    country_key = @config[:us_carriers] if @config[:us_carriers] != nil
    if @config[:international_carriers] != nil
      (destination[:country] != 'US') ? country_key = @config[:international_carriers] : country_key = @config[:us_carriers]
    end
    if po_box(destination)
      country_key.delete('FedEx')
      country_key.delete('UPS')
      country_key << 'USPS' if !country_key.include?('USPS')
      @config[:shown_rates] += @config[:po_box_rates]
    end
    if ship_selected != nil
      country_key.reject! {|x| x != 'FedEx'} if ship_selected[0..4] == 'FedEx'
      country_key.reject! {|x| x != 'USPS'} if ship_selected[0..3] == 'USPS'
      country_key.reject! {|x| x != 'UPS'} if ship_selected[0..2] == 'UPS'
      country_key.reject! {|x| x != 'RL'} if ship_selected[0..4] == 'Truck'
    end


    if country_key.include?('FedEx') && @truck_only.to_i == 0
      fedex_rates = c.pull_fedex(origin, location_destination, packages)
      all_rates += fedex_rates
    end
    if country_key.include?('USPS') && @truck_only.to_i == 0
      usps_rates = c.pull_usps(origin, location_destination, packages)
      all_rates += usps_rates
    end
    if country_key.include?('UPS') && @truck_only.to_i == 0
      ups_rates = c.pull_ups(origin, location_destination, packages)
      all_rates += ups_rates
    end

    if country_key.include?('RL') && @truck_only.to_i == 1
        rl = RLQuote.new(@cart_items, @config)
        rl_quote = (rl.freight_request(destination)).to_i
        # retry
        rl_quote = (rl.freight_request(destination)).to_i if rl_quote == 0
        rl_quote = (rl.freight_request(destination)).to_i if rl_quote == 0
        all_rates += [['Truck Shipping', rl_quote*100 ]] if rl_quote != 0
    end

    all_rates = [] if all_rates == nil
    all_rates
  end

  def multiplier(quotes)
    if @config[:rate_multiplier].to_d != 1 && quotes != nil && quotes.length > 0


#binding.pry

      quotes.each do |q|
        if q[0][0..4] == 'FedEx' && q[0][0..7] != 'FedEx Gr'  && @config[:fedex_express_multiplier].to_d != 1
          q[1] = q[1] * @config[:fedex_express_multiplier].to_d

        elsif q[0] == 'USPS Media Mail' && @config[:media_mail_multiplier].to_d != 1
          q[1] = q[1] * @config[:media_mail_multiplier].to_d

        elsif q[0] == 'USPS First-Class Mail Parcel' && @config[:media_mail_multiplier].to_d != 1
          q[1] = q[1] * @config[:media_mail_multiplier].to_d

        elsif q[0] !=  'Truck Shipping'
          q[1] = q[1] * @config[:rate_multiplier].to_d
        end
      end
    end
    quotes
  end

  def notes
    @notes
  end


end
