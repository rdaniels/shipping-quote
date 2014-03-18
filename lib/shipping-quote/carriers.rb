#require 'pry'
require 'active_shipping'
#require 'atomic_mem_cache_store'
include ActiveSupport::Cache
include ActiveMerchant::Shipping


class PullCarriers
  attr_accessor :notes

  def initialize(config)
    @config = config
    @notes = []
    #@diskcache = MemCacheStore.new #('/tmp/shipping', 10800) # 3 hours
    @cache = FileStore.new('./tmp/cache')
  end

  def pull_fedex (origin, location_destination, packages)
    cache_name = 'fedex' + packages_to_cache_name(location_destination, packages)

    fedex_rates = @cache.read(cache_name)
    if fedex_rates == nil
      begin
        fedex = FedEx.new(login: @config[:fedex][:login], password: @config[:fedex][:password], key: @config[:fedex][:key], account: @config[:fedex][:account], meter: @config[:fedex][:meter])
        response = fedex.find_rates(origin, location_destination, packages)
        fedex_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @cache.write(cache_name, fedex_rates, :expires_in => 2.hours)
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

    usps_rates = @cache.read(cache_name)
    if usps_rates == nil
      begin
        usps = USPS.new(login: @config[:usps][:login])
        response = usps.find_rates(origin, location_destination, packages)
        usps_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @cache.write(cache_name, usps_rates, :expires_in => 2.hours)
      rescue #=> error
        usps_rates = []
        @notes << 'USPS can not produce quotes at this time' # + error.response.message
      end
    end
    usps_rates
  end


  def pull_ups (origin, location_destination, packages)
    cache_name = 'ups' + packages_to_cache_name(location_destination, packages)

    ups_rates = @cache.read(cache_name)
    if ups_rates == nil
      begin
        ups = UPS.new(login: @config[:ups][:login], password: @config[:ups][:password], key: @config[:ups][:key])
        response = ups.find_rates(origin, location_destination, packages)
        ups_rates = response.rates.sort_by(&:price).collect { |rate| [rate.service_name, rate.price] }
        @cache.write(cache_name, ups_rates, :expires_in => 2.hours)
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
