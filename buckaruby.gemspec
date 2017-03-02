# coding: utf-8

lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'buckaruby/version'

Gem::Specification.new do |spec|
  spec.name          = "buckaruby"
  spec.version       = Buckaruby::VERSION
  spec.authors       = ["Kentaa"]
  spec.email         = ["support@kentaa.nl"]
  spec.summary       = "Ruby library for communicating with the Buckaroo Payment Engine 3.0."
  spec.description   = "The Buckaruby gem provides a Ruby library for communicating with the Buckaroo Payment Engine 3.0."
  spec.homepage      = "https://github.com/KentaaNL/buckaruby"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^spec/})
  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.0.0"

  spec.add_development_dependency "bundler", "~> 1.7"
  spec.add_development_dependency "rake", "~> 10.0"
  spec.add_development_dependency "rspec", "~> 3.5.0", ">= 3.5.0"
  spec.add_development_dependency "webmock", "~> 2.3", ">= 2.3.2"
end
