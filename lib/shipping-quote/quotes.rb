require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping

require_relative 'carriers'
#include 'carriers'

class Quote
  attr_accessor :notes


  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
  end


  def quotes(destination, packages)
    all_rates = []
    c = PullCarriers.new(@config)
    origin = Location.new(@config[:origin])
    location_destination = Location.new(destination)

    country_key = %w(USPS FedEx)
    country_key = @config[:us_carriers] if @config[:us_carriers] != nil
    if @config[:canada_carriers] != nil
      (destination[:country] == 'CA') ? country_key = @config[:canada_carriers] : country_key = @config[:us_carriers]
    end

    if country_key.include? 'USPS'
      usps_rates = c.pull_usps(origin, location_destination, packages)
      all_rates += usps_rates
    end
    if country_key.include? 'UPS'
      ups_rates = c.pull_ups(origin, location_destination, packages)
      all_rates += ups_rates
    end
    if country_key.include? 'FedEx'
      fedex_rates = c.pull_fedex(origin, location_destination, packages)
      all_rates += fedex_rates
    end

    all_rates.each { |line| line[1] = (line[1] * @config[:rate_multiplier].to_d).round(0) }
    all_rates
  end

  def multiplier(quotes)
    if @config[:rate_multiplier].to_d != 1
      quotes.each do |q|
        if q[0] == 'USPS Media Mail' && @config[:media_mail_multiplier].to_d != 1
          q[1] = q[1] * @config[:media_mail_multiplier].to_d
        else
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