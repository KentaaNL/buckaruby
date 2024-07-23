# frozen_string_literal: true

require_relative 'lib/buckaruby/version'

Gem::Specification.new do |spec|
  spec.name          = 'buckaruby'
  spec.version       = Buckaruby::VERSION
  spec.authors       = ['Kentaa']
  spec.email         = ['developers@kentaa.nl']
  spec.summary       = 'Ruby library for communicating with the Buckaroo Payment Engine 3.0.'
  spec.description   = 'The Buckaruby gem provides a Ruby library for communicating with the Buckaroo Payment Engine 3.0.'
  spec.homepage      = 'https://github.com/KentaaNL/buckaruby'
  spec.license       = 'MIT'

  spec.metadata      = { 'rubygems_mfa_required' => 'true' }

  # Specify which files should be added to the gem when it is released.
  spec.files         = Dir['CHANGELOG.md', 'LICENSE.txt', 'README.md', 'lib/**/*']

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.required_ruby_version = '>= 2.7.0'

  spec.add_development_dependency 'bundler', '~> 2.0'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
  spec.add_development_dependency 'webmock', '~> 3.0'

  spec.add_dependency 'bigdecimal'
  spec.add_dependency 'logger'
end
