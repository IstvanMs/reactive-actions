# frozen_string_literal: true

module ReactiveActions
  # Main controller for handling reactive action requests
  # Processes action execution and manages error handling for the ReactiveActions engine
  class ReactiveActionsController < ApplicationController
    # Allow this action to handle any HTTP method
    def execute
      ReactiveActions.logger.info "ReactiveActionsController#execute[#{request.method}]: #{params.inspect}"
      build_reactive_action.run
    rescue ReactiveActions::Error => e
      handle_reactive_actions_error(e)
    rescue StandardError => e
      handle_standard_error(e)
    end

    private

    # Build and initialize the action
    def build_reactive_action
      initialize_action(extract_action_name, extract_action_params)
    end

    # Extract and validate action_name parameter
    def extract_action_name
      action_name = params[:action_name]
      raise ReactiveActions::MissingParameterError, 'Missing action_name parameter' if action_name.blank?

      # Sanitize action_name to prevent code injection
      sanitized_name = action_name.to_s.strip
      raise ReactiveActions::InvalidParametersError, 'Invalid action_name format' unless sanitized_name.match?(/\A[a-zA-Z_][a-zA-Z0-9_]*\z/)

      sanitized_name
    end

    # Extract and sanitize action_params with proper strong parameters
    def extract_action_params
      raw_params = params[:action_params]
      return {} if raw_params.blank?

      # For JSON requests, the params might already be a hash
      if raw_params.is_a?(String)
        begin
          parsed_params = JSON.parse(raw_params)
          permit_nested_params(parsed_params)
        rescue JSON::ParserError
          raise ReactiveActions::InvalidParametersError, 'Invalid JSON in action_params'
        end
      else
        # Handle ActionController::Parameters, Hash, or any other object
        permit_nested_params(raw_params)
      end
    end

    # Recursively permit nested parameters
    # This allows for flexible parameter structures while maintaining security
    def permit_nested_params(params)
      case params
      when ActionController::Parameters, Hash
        permit_hash_params(params)
      when Array
        params.map { |item| permit_nested_params(item) }
      else
        sanitize_param_value(params)
      end
    end

    # Handle hash-like parameters (ActionController::Parameters or Hash)
    def permit_hash_params(params)
      permitted_hash = {}
      params.each do |key, value|
        sanitized_key = sanitize_param_key(key)
        next if sanitized_key.nil?

        permitted_hash[sanitized_key] = permit_nested_params(value)
      end
      permitted_hash
    end

    # Sanitize parameter keys to prevent injection attacks
    def sanitize_param_key(key)
      key_str = key.to_s.strip

      # Only allow alphanumeric characters, underscores, and hyphens
      return nil unless key_str.match?(/\A[a-zA-Z0-9_-]+\z/)

      # Prevent keys that start with dangerous prefixes
      dangerous_prefixes = %w[__ eval exec system `]
      return nil if dangerous_prefixes.any? { |prefix| key_str.start_with?(prefix) }

      key_str
    end

    # Sanitize parameter values based on type
    def sanitize_param_value(value)
      return value if safe_primitive_type?(value)
      return truncate_string(value) if value.is_a?(String)

      # For other types, preserve original value if reasonable
      value.respond_to?(:to_s) && !value.is_a?(Object) ? truncate_string(value.to_s) : value
    end

    # Check if value is a safe primitive type that doesn't need sanitization
    def safe_primitive_type?(value)
      value.is_a?(Numeric) || value.is_a?(TrueClass) || value.is_a?(FalseClass) ||
        value.nil? || value.is_a?(Time) || value.is_a?(Date) || value.is_a?(DateTime)
    end

    # Truncate strings to prevent memory exhaustion
    def truncate_string(string)
      max_length = string == string.to_s ? 10_000 : 1_000
      string.length > max_length ? string[0, max_length] : string
    end

    def handle_reactive_actions_error(exception)
      error_mapping = {
        'ActionNotFoundError' => [:not_found, 'NOT_FOUND'],
        'MissingParameterError' => [:bad_request, 'MISSING_PARAMETER'],
        'InvalidParametersError' => [:bad_request, 'INVALID_PARAMETERS'],
        'UnauthorizedError' => [:forbidden, 'UNAUTHORIZED'],
        'ActionExecutionError' => [:unprocessable_entity, 'EXECUTION_ERROR']
      }

      error_type = exception.class.name.demodulize
      status, code = error_mapping[error_type]

      ReactiveActions.logger.error "#{error_type}: #{exception.message}"
      render_error(exception, status, code)
    end

    def handle_standard_error(exception)
      ReactiveActions.logger.error "Unexpected error: #{exception.message}"
      render_error(exception, :internal_server_error, 'SERVER_ERROR')
    end

    # Helper method to render standardized error responses
    def render_error(exception, status, code)
      render json: {
        success: false,
        error: {
          type: exception.class.name.demodulize,
          message: exception.message,
          code: code
        }
      }, status: status
    end

    # Find and execute the requested action
    def initialize_action(action_name, action_params)
      # Convert snake_case action name to CamelCase class name
      # e.g., "update_user" becomes "UpdateUserAction"
      class_name = build_class_name(action_name)

      # Find the action class - this will look in several places:
      # 1. ReactiveActions::{ClassName} (e.g., ReactiveActions::UpdateUserAction)
      # 2. {ClassName} (e.g., UpdateUserAction) in global namespace
      action_class = find_action_class(class_name)

      # Initialize the action and return it
      # Add ** to convert hash to keyword arguments
      action_class.new(self, **action_params.symbolize_keys)
    end

    def build_class_name(action_name)
      class_name = action_name.to_s.camelize
      # Add "Action" suffix if it doesn't already end with it
      class_name.end_with?('Action') ? class_name : "#{class_name}Action"
    end

    # Find an action class using various lookup strategies
    def find_action_class(class_name)
      # First try within the ReactiveActions namespace
      "ReactiveActions::#{class_name}".constantize
    rescue NameError
      begin
        # Then try in the global namespace
        class_name.constantize
      rescue NameError
        raise ReactiveActions::ActionNotFoundError, "Action '#{class_name.sub(/Action$/, '')}' not found"
      end
    end
  end
end
