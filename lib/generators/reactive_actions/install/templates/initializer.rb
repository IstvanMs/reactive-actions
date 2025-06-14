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

# JavaScript Client Configuration
# ================================
# The JavaScript client is automatically initialized in application.js
# You can reconfigure it at runtime if needed:
#
# ReactiveActions.configure({
#   baseUrl: '/custom/path/execute',
#   enableAutoBinding: true,
#   enableMutationObserver: true,
#   defaultHttpMethod: 'POST'
# }).reinitialize();
#
# Available globally as window.ReactiveActions
