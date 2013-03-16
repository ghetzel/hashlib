require 'rspec'
require 'hashlib'

class AppWorld
  include RSpec::Expectations
  include RSpec::Matchers
end

World do
  AppWorld.new
end

