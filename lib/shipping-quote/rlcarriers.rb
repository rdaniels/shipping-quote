require 'net/http'
require 'cgi'

class RLQuote
  attr_accessor :notes

  def initialize(cart_items, config, truck_only=nil)
    @cart_items, @config, @truck_only = cart_items, config, truck_only
    @notes = []
  end

  def http_get(domain,path,params)
    return Net::HTTP.get(domain, "#{path}?".concat(params.collect { |k,v| "#{k}=#{CGI::escape(v.to_s)}" }.join('&'))) if not params.nil?
    return Net::HTTP.get(domain, path)
  end

  def freight_request(destination)
    path = '/b2brateparam.asp'
    params = {"id" => "5173944631",
      "origin" => "48910",
      "dest" => destination[:postal_code],
      "class1" => ship_class,
      "weight1" => get_weight,
      "delnotify" => 'X',
      "hazmat" => check_ormd,
      "resdel" => residential
    }
    res = http_get("www.rlcarriers.com", path, params)
    my_hash = Hash.from_xml(res)

    if my_hash ['xml']['ratequote']['netcharges'] == nil
      @notes == 'Truck Quote not available'
      0
    else
      my_hash ['xml']['ratequote']['netcharges'].gsub('$','').to_d
    end
    # begin
    #   res = http_get("www.rlcarriers.com", path, params)
    #   my_hash = Hash.from_xml(res)
    #   my_hash ['xml']['ratequote']['netcharges'].gsub('$','').to_d
    # rescue => error
    #   0
    # end


  end

  def ship_class
    x = 70
    kiln = @cart_items.find_all { |item| item.name != nil && item.name.match(/kiln/) && item.weight > 15 }
    x = 85 if kiln.length > 0

    large_sheet = @cart_items.find_all { |item| (item.ref01.match(/-lg/) || item.ref01.match(/-sht/)) && item.isGlass.to_i == 1 }
    sum = large_sheet.map(&:qty).inject(0, &:+)
    x = 65 if sum >= 30

    lead = @cart_items.find_all { |item| item.shipCode == 'LEA' }
    x = 60 if lead.length > 0 && x == 70
    x
  end

  def check_ormd
    x = ''
    ormd_items = @cart_items.find_all { |item| item.ormd != nil && item.ormd.to_i > 0 }
    x = 'X' if ormd_items.length > 0
    x
  end

  def residential(pricemode=1)
    x = ''
    x = 'X' if pricemode == 6
    x
  end

  def get_weight(sm_glass_pieces=0, lg_glass_pieces=0)
    weight = 0
    @cart_items.each { |item| weight += item.weight.to_d * item.qty.to_i if item.weight != nil }
    weight += sm_glass_pieces * 2
    weight += lg_glass_pieces * 5
    weight
  end
end
