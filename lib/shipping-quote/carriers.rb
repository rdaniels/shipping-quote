# require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping


class PullCarriers
  attr_accessor :notes

  def initialize(config)
    @config = config
    @notes = []
  end

  def pull_fedex (origin, location_destination, packages)
    fedex = FedEx.new(login: @config[:fedex][:login], password: @config[:fedex][:password],
                      key: @config[:fedex][:key], account: @config[:fedex][:account], meter: @config[:fedex][:meter])

    begin
      response = fedex.find_rates(origin, location_destination, packages)
      fedex_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
    rescue #=> error
      #raise error
      fedex_rates = []
      @notes << 'FedEx can not produce quote at this time' # + error.response.message
    end
    fedex_rates
  end


  def pull_usps (origin, location_destination, packages)
    usps = USPS.new(login: @config[:usps][:login])

    begin
      response = usps.find_rates(origin, location_destination, packages)
      usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
    rescue #=> error
      usps_rates = []
      @notes << 'USPS can not produce quotes at this time' # + error.response.message
    end
    usps_rates
  end


  def pull_ups (origin, location_destination, packages)
    ups = UPS.new(login: @config[:ups][:login], password: @config[:ups][:password], key: @config[:ups][:key])
    begin
      response = ups.find_rates(origin, location_destination, packages)
      ups_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
    rescue #=> error
      ups_rates = []
      @notes << 'UPS can not produce quotes at this time' # + error.response.message
    end
    ups_rates
  end


  def notes
    @notes
  end
end
