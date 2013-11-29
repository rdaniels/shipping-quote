# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'shipping_gem/version'

Gem::Specification.new do |spec|
  spec.name          = 'shipping_gem'
  spec.version       = ShippingGem::VERSION
  spec.authors       = ['Rob Daniels']
  spec.email         = %w(rob@danielscorporation.com)
  spec.description   = 'Calculates shipping and boxing charges'
  spec.summary       = 'Calculates shipping and boxing charges'
  spec.homepage      = ''
  spec.license       = 'MIT'

  spec.files         = %w(lib/shipping_gem.rb) #`git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = %w(lib)

  spec.add_development_dependency 'bundler', '~> 1.3'
  spec.add_development_dependency 'rake'

  spec.add_development_dependency 'active_shipping'
end
