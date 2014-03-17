#require 'pry'
require 'active_shipping'
require 'diskcached'
include ActiveMerchant::Shipping


class PullCarriers
  attr_accessor :notes

  def initialize(config)
    @config = config
    @notes = []
    @diskcache = Diskcached.new('./tmp', 10800) # 3 hours
  end

  def pull_fedex (origin, location_destination, packages)
    cache_name = 'fedex' + packages_to_cache_name(location_destination, packages)
    fedex_rates = @diskcache.cache(cache_name) do
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
    end
    File.delete("./tmp/fedex" + packages_to_cache_name(location_destination, packages) + '.cache') if fedex_rates[0] == 'FedEx can not produce quote at this time'
    fedex_rates
  end


  def pull_usps (origin, location_destination, packages)
    cache_name = 'usps' + packages_to_cache_name(location_destination, packages)
    usps_rates = @diskcache.cache(cache_name) do
      usps = USPS.new(login: @config[:usps][:login])
      begin
        response = usps.find_rates(origin, location_destination, packages)
        usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
      rescue #=> error
        usps_rates = []
        @notes << 'USPS can not produce quotes at this time' # + error.response.message
      end
    end
    File.delete("./tmp/usps" + packages_to_cache_name(location_destination, packages) + '.cache') if usps_rates[0] == 'USPS can not produce quotes at this time'
    usps_rates
  end


  def pull_ups (origin, location_destination, packages)
    cache_name = 'ups' + packages_to_cache_name(location_destination, packages)
    ups_rates = @diskcache.cache(cache_name) do
      ups = UPS.new(login: @config[:ups][:login], password: @config[:ups][:password], key: @config[:ups][:key])
      begin
        response = ups.find_rates(origin, location_destination, packages)
        ups_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
      rescue #=> error
        ups_rates = []
        @notes << 'UPS can not produce quotes at this time' # + error.response.message
      end
    end
    File.delete("./tmp/ups" + packages_to_cache_name(location_destination, packages) + '.cache') if ups_rates[0] == 'UPS can not produce quotes at this time'
    ups_rates
  end


  def packages_to_cache_name(location_destination, packages)
    cache_name = location_destination.country.to_s.gsub(' ','') + location_destination.zip.to_s
    packages.each do |p|
      cache_name += p.weight.to_i.to_s + '_'
      cache_name += p.inches[0].to_s + p.inches[1].to_s + p.inches[2].to_s
    end
    cache_name
  end


  def notes
    @notes
  end
end
