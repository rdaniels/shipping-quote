require 'spec_helper'
#require 'shipping_gem'

module ShippingGem
  describe Shipping do
    let(:output) { double('output').as_null_object }
    let(:shipping) { Shipping.new }

    it 'says hi' do
      expect(Shipping.hi).to be == "Hello World!"
    end

    it 'initializes hash' do
      output.to be == {}
      #expect(Shipping.new).should_receieve(@packages).once
    end
    it 'returns no packages' do

      expect(@packages).to be == []
      ship = Shipping.new
      ship.create_packages
    end
  end
end