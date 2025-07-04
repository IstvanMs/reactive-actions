# Add this to test/dummy/config/initializers/reactive_actions.rb

# ReactiveActions configuration
ReactiveActions.configure do |config|
  # Configure methods to delegate from the controller to action classes
  # config.delegated_controller_methods += [:custom_method]

  # Configure instance variables to delegate from the controller to action classes
  # config.delegated_instance_variables += [:custom_variable]
  
  config.rate_limiting_enabled = true
  config.global_rate_limiting_enabled = false
end

# Set the logger for ReactiveActions
ReactiveActions.logger = Rails.logger