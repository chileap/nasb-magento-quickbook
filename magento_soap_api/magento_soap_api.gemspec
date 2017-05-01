# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'magento_soap_api/version'

Gem::Specification.new do |spec|
  spec.name          = "magento_soap_api"
  spec.version       = MagentoSoapApi::VERSION
  spec.authors       = ["chileap"]
  spec.email         = ["chileapchhin@gmail.com"]

  spec.description   = %q{Ruby wrapper for Magento's SOAP API. Allows you to download orders using filters, invoice orders, and update orders as shipped in Magento.}
  spec.summary       = %q{Ruby wrapper for Magento's SOAP API}
  spec.homepage      = "https://github.com/rotati/nasb-magento-quickbooks"
  spec.license       = "MIT"

  spec.files         = `git ls-files`.split($/)
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.files         = Dir['lib/**/*.rb', 'lib/*.rb']
  spec.require_paths = ["lib"]

  spec.add_dependency "savon", "2.11.1"
  spec.add_dependency "httpclient", "~> 2.7.1"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "factory_girl", "~> 4.3.0"
  spec.add_development_dependency "pry", "~> 0.9.12 "
  spec.add_development_dependency "rake", "~> 0.9.6"
  spec.add_development_dependency "rspec", "~> 2.14"
  spec.add_development_dependency "vcr", "~> 2.8.0"
end
