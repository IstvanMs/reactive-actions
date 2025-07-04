# frozen_string_literal: true

require 'reactive_actions/version'
require 'reactive_actions/configuration'
require 'reactive_actions/engine'
require 'reactive_actions/errors'
require 'reactive_actions/rate_limiter'
require 'reactive_actions/controller/rate_limiter'
require 'reactive_actions/concerns/rate_limiter'
require 'reactive_actions/concerns/security_checks'
require 'reactive_actions/reactive_action'

# Main namespace for the ReactiveActions gem
# Provides functionality for creating and executing reactive actions in Rails applications
module ReactiveActions
  class << self
    attr_writer :logger

    def logger
      @logger ||= Rails.logger
    end
  end
end
