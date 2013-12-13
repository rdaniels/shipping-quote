# require "shipping-quote/version"
require 'pry'
require 'active_shipping'
include ActiveMerchant::Shipping
require 'yaml'

module ShippingQuote

  # Configuration defaults
  @config = { :box_max_weight => 25 }
  @valid_config_keys = @config.keys

  #TODO: setup path_to_yaml_file

  # Configure through hash
  def self.configure(opts = {})
    opts.each {|k,v| @config[k.to_sym] = v if @valid_config_keys.include? k.to_sym}
  end

  # Configure through yaml file
  def self.configure_with(path_to_yaml_file)
    begin
      config = YAML::load(IO.read(path_to_yaml_file))
    rescue Errno::ENOENT
      log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
    rescue Psych::SyntaxError
      log(:warning, "YAML configuration file contains invalid syntax. Using defaults."); return
    end

    configure(config)
  end

  def self.config
    @config
  end


  class Shipping
    attr_accessor :boxing_charge

    def initialize(cart_items)
      @cart_items = cart_items
      @cart_items = [] if cart_items == nil
      @config = { box_max_weight: 25, box_lead_weight: 31 }
      begin
        @config = YAML::load(IO.read("#{RAILS_ENV}/config/shipping-quote.yml"))
      rescue
        #log(:warning, "YAML configuration file couldn't be found. Using defaults."); return
      end
    end


    def create_packages
      @packages = []
      @boxing_charge = 0
      @truck_only = 0

      regular_item_weight = 0
      glass_pieces = 0
      dichro_pieces = 0
      add_lead_box = 0

      #binding.pry
      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase

        glass_pieces += item.qty * 2 if item.isGlass == 1 && (item.glassConverter == nil || item.glassConverter == 0)
        glass_pieces += item.qty * item.glassConverter if item.isGlass == 1 && (item.glassConverter != nil && item.glassConverter > 0)
        dichro_pieces += item.qty if item.isGlass == 3

        if item.isGlass == nil || item.isGlass == 0 || item.isGlass == 2
          if shipCode == 'SHA' || shipCode == 'TRK' || (item.weight > @config[:box_max_weight] && (shipCode == 'UPS' || shipCode == ''))
            (1..item.qty).each { @packages << Package.new((item.weight * 16), [5, 5, 5], :units => :imperial) }
          else
            if shipCode == 'LEA'
              add_lead_box = 1
            else
              # backorder = -1 normal item out of stock, purchaseCode for special order (2, 20+), 999 truck item
              regular_item_weight += item.weight * item.qty  #if item.backorder == 0
            end
          end
        end
      end

      # regular items
      full_item_boxes = (regular_item_weight.to_f / @config[:box_max_weight]).to_i
      (1..full_item_boxes).each { @packages << Package.new((@config[:box_max_weight] * 16), [5, 5, 5], :units => :imperial) }
      partial_item_box = regular_item_weight - (full_item_boxes * @config[:box_max_weight])
      @packages << Package.new((partial_item_box * 16), [5, 5, 5], :units => :imperial) if partial_item_box > 0

      # lead
      @packages << Package.new((@config[:box_lead_weight] * 16), [5, 5, 5], :units => :imperial) if add_lead_box == 1

      @boxing_charge = 1

      @packages
    end

    def truck_only
      @cart_items.each do |item|
        (item.shipCode == nil) ? shipCode = '' : shipCode = item.shipCode.upcase
          return 1 if shipCode == 'TRK'
      end
      return 0
    end

  end
end
