require_relative "boot"

require "rails/all"
require "reactive_actions"

Bundler.require(*Rails.groups)

module Dummy
  class Application < Rails::Application
    config.load_defaults Rails::VERSION::STRING.to_f
    
    # For engines, we need to tell Rails where to find the engine's files
    config.eager_load_paths << File.expand_path('../../../lib', __dir__)
  end
end
