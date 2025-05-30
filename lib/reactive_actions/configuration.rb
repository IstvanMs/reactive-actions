# frozen_string_literal: true

# ReactiveActions module provides functionality for creating and executing reactive actions in Rails applications
module ReactiveActions
  # Configuration class for ReactiveActions
  # Manages settings for controller method delegation and instance variable delegation
  class Configuration
    attr_accessor :delegated_controller_methods, :delegated_instance_variables

    def initialize
      # Default methods to delegate
      @delegated_controller_methods = %i[
        render redirect_to head params
        session cookies flash request response
      ]

      # Default instance variables to delegate
      @delegated_instance_variables = []
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
