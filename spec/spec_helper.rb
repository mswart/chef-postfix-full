require 'chefspec'

# load support files:
Dir[File.expand_path('spec/support/**/*.rb')].each {|f| require f}

# configure rspec:
RSpec.configure do |config|
  config.order = 'random'

  config.expect_with :rspec do |c|
    # Only allow expect syntax
    c.syntax = :expect
  end
end
