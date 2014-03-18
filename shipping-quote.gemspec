# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name          = 'shipping-quote'
  spec.version       = '0.1.14'
  spec.date          = '2013-12-11'
  spec.authors       = ['Rob Daniels']
  spec.email         = %w(rob@danielscorporation.com)
  spec.description   = 'Calculates shipping and boxing charges'
  spec.summary       = 'Seperates cart items into boxes and passes to ActiveShipping for quote.'
  spec.homepage      = 'https://github.com/rdaniels/shipping-quote'
  spec.license       = 'MIT'

  spec.files         = %w(lib/shipping-quote.rb) #`git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  # spec.require_paths = %w(lib)

  spec.add_dependency 'bundler', '~> 1.3'
  spec.add_dependency 'rake'
  spec.add_dependency 'active_shipping'
  #spec.add_dependency 'atomic_mem_cache_store'

  spec.add_development_dependency 'rspec-core', '3.0.0.beta1'
  spec.add_development_dependency 'pry-plus'
  #spec.add_development_dependency 'faker'
end

# build gem
# gem build shipping-quote.gemspec

# install gem
# sudo gem install ./shipping-quote-0.0.11.gem
