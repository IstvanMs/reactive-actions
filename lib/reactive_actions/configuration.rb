# frozen_string_literal: true

# ReactiveActions provides functionality for creating and executing reactive actions in Rails applications
module ReactiveActions
  # Configuration class for ReactiveActions
  # Manages settings for controller method delegation, instance variable delegation, and rate limiting
  class Configuration
    attr_accessor :delegated_controller_methods, :delegated_instance_variables, :global_rate_limit, :global_rate_limit_window, :rate_limit_key_generator, :rate_limit_cost_calculator

    # Rate limiting configuration
    attr_accessor :rate_limiting_enabled, :global_rate_limiting_enabled

    def initialize
      # Default methods to delegate
      @delegated_controller_methods = %i[
        render redirect_to head params
        session cookies flash request response
      ]

      # Default instance variables to delegate
      @delegated_instance_variables = []

      # Rate limiting defaults - DISABLED by default
      @rate_limiting_enabled = false           # Master switch for all rate limiting
      @global_rate_limiting_enabled = false    # Global controller-level rate limiting
      @global_rate_limit = 600                 # 600 requests per minute (10/second)
      @global_rate_limit_window = 1.minute     # per minute for responsive rate limiting
      @rate_limit_key_generator = nil          # Use default logic if nil
      @rate_limit_cost_calculator = nil        # Use default cost of 1 if nil
    end

    # Helper methods for checking rate limiting status
    def rate_limiting_available?
      @rate_limiting_enabled
    end

    def global_rate_limiting_active?
      @rate_limiting_enabled && @global_rate_limiting_enabled
    end
  end

  class << self
    attr_writer :configuration

    def configuration
      @configuration ||= Configuration.new
    end

    def configure
      yield(configuration)
    end
  end
end
