# frozen_string_literal: true

require 'rails'
require 'rails/generators'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require File.expand_path('../test/dummy/config/environment', __dir__)

# Prevent database truncation if the environment is production
abort('The Rails environment is running in production mode!') if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'

# Add additional requires below this line. Rails is not loaded until this point!

# Load support files
Dir[ReactiveActions::Engine.root.join('spec/support/**/*.rb')].each { |f| require f }

RSpec.configure do |config|
  config.fixture_paths = ["#{ReactiveActions::Engine.root}/spec/fixtures"]
  config.use_transactional_fixtures = true
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!

  config.include FactoryBot::Syntax::Methods

  # Ensure Rails logs to test.log during specs
  config.before(:suite) do
    Rails.logger = ActiveSupport::Logger.new(Rails.root.join('log/test.log'))
    Rails.logger.level = Logger::DEBUG
  end
end
