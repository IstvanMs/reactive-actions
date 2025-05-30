# frozen_string_literal: true

module ReactiveActions
  # Base error class for all ReactiveActions errors
  class Error < StandardError; end

  # Raised when an action is not found
  class ActionNotFoundError < Error; end

  # Raised when an action fails to execute properly
  class ActionExecutionError < Error; end

  # Raised when parameters are invalid
  class InvalidParametersError < Error; end

  # Raised when a required parameter is missing
  class MissingParameterError < InvalidParametersError; end

  # Raised when a parameter has an invalid type or format
  class ParameterTypeError < InvalidParametersError; end

  # Raised when the user is not authorized to perform the action
  class UnauthorizedError < Error; end
end
