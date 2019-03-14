# frozen_string_literal: true

require 'rubygems'
require 'bundler/setup'
require 'webmock/rspec'

require 'buckaruby'

RSpec.configure do |config|
  config.color     = true
  config.formatter = 'documentation'

  config.raise_errors_for_deprecations!

  config.disable_monkey_patching!
end
