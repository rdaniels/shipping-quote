#require 'pry'
require 'active_shipping'
require 'diskcached'
include ActiveMerchant::Shipping


class PullCarriers
  attr_accessor :notes

  def initialize(config)
    @config = config
    @notes = []
    @diskcache = Diskcached.new('/tmp/shipping', 10800) # 3 hours
  end

  def pull_fedex (origin, location_destination, packages)
    cache_name = 'fedex' + packages_to_cache_name(location_destination, packages)
    #binding.pry
    if Pathname.new("/tmp/shipping/" + cache_name + '.cache').exist?

      fedex_rates = @diskcache.get(cache_name)
    else # Diskcached::NotFound # prevents easy replacement, but is safer. - See more at: http://mervine.net/diskcached-simple-disk-cacheing-for-ruby#sthash.0gD5Y6nY.dpuf
      begin
        fedex = FedEx.new(login: @config[:fedex][:login], password: @config[:fedex][:password], key: @config[:fedex][:key], account: @config[:fedex][:account], meter: @config[:fedex][:meter])
        response = fedex.find_rates(origin, location_destination, packages)
        fedex_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @diskcache.set(cache_name, fedex_rates)
      rescue #=> error
        #raise error
        fedex_rates = []
        @notes << 'FedEx can not produce quote at this time' # + error.response.message
      end
    end
    fedex_rates
  end


  def pull_usps (origin, location_destination, packages)
    cache_name = 'usps' + packages_to_cache_name(location_destination, packages)
    if Pathname.new("/tmp/shipping/" + cache_name + '.cache').exist?
      usps_rates = @diskcache.get(cache_name)
    else
      begin
        usps = USPS.new(login: @config[:usps][:login])
        response = usps.find_rates(origin, location_destination, packages)
        usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @diskcache.set(cache_name, usps_rates)
      rescue #=> error
        usps_rates = []
        @notes << 'USPS can not produce quotes at this time' # + error.response.message
      end
    end
    usps_rates
  end


  def pull_ups (origin, location_destination, packages)
    cache_name = 'ups' + packages_to_cache_name(location_destination, packages)
    if Pathname.new("/tmp/shipping/" + cache_name + '.cache').exist?
      ups_rates = @diskcache.get(cache_name)
    else
      begin
        ups = UPS.new(login: @config[:ups][:login], password: @config[:ups][:password], key: @config[:ups][:key])
        response = ups.find_rates(origin, location_destination, packages)
        ups_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @diskcache.set(cache_name, ups_rates)
      rescue #=> error
        ups_rates = []
        @notes << 'UPS can not produce quotes at this time' # + error.response.message
      end
    end
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
