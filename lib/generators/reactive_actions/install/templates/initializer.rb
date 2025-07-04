# frozen_string_literal: true

# ReactiveActions configuration
ReactiveActions.configure do |config|
  # Configure methods to delegate from the controller to action classes
  # config.delegated_controller_methods += [:custom_method]

  # Configure instance variables to delegate from the controller to action classes
  # config.delegated_instance_variables += [:custom_variable]

  # Rate Limiting Configuration
  # ============================
  
<% if rate_limiting_config[:rate_limiting_enabled] -%>
  # Rate limiting is enabled
  config.rate_limiting_enabled = true

<% if rate_limiting_config[:global_rate_limiting_enabled] -%>
  # Global controller-level rate limiting is enabled
  config.global_rate_limiting_enabled = true
  config.global_rate_limit = <%= rate_limiting_config[:global_rate_limit] || 600 %>
  config.global_rate_limit_window = <%= rate_limiting_config[:global_rate_limit_window] || '1.minute' %>

<% else -%>
  # Global rate limiting is disabled
  config.global_rate_limiting_enabled = false

<% end -%>
<% if rate_limiting_config[:custom_key_generator] -%>
  # Custom rate limit key generator
  # Uncomment and customize as needed:
  # config.rate_limit_key_generator = ->(request, action_name) do
  #   # Example: user-based key with action scope
  #   user_id = request.headers['X-User-ID'] || 'anonymous'
  #   "#{action_name}:user:#{user_id}"
  # end

<% end -%>
<% else -%>
  # Rate limiting is disabled by default
  # To enable rate limiting, uncomment and configure:
  # config.rate_limiting_enabled = true
  # config.global_rate_limiting_enabled = true
  # config.global_rate_limit = 600
  # config.global_rate_limit_window = 1.minute
  
  # Custom rate limit key generator (optional)
  # config.rate_limit_key_generator = ->(request, action_name) do
  #   # Example: user-based key with action scope
  #   user_id = request.headers['X-User-ID'] || 'anonymous'
  #   "#{action_name}:user:#{user_id}"
  # end

<% end -%>
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