# frozen_string_literal: true

# ReactiveActions configuration
ReactiveActions.configure do |config|
  # Configure methods to delegate from the controller to action classes
  # config.delegated_controller_methods += [:custom_method]

  # Configure instance variables to delegate from the controller to action classes
  # config.delegated_instance_variables += [:custom_variable]
end

# Set the logger for ReactiveActions
ReactiveActions.logger = Rails.logger
