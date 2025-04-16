# frozen_string_literal: true

module ReactiveActions
  class ReactiveActionsController < ApplicationController
    # Allow this action to handle any HTTP method
    def execute
      ReactiveActions.logger.info "ReactiveActionsController#execute called with method: #{request.method}, params: #{params.inspect}"
      
      # Example action handling
      action_name = params[:action_name]
      action_params = params[:action_params] || {}
      request_method = request.method
      
      # Process the action (this is just an example)
      result = { 
        success: true,
        http_method: request_method,
        action: action_name,
        message: "Action '#{action_name}' executed successfully via #{request_method}",
        data: action_params
      }
      
      render json: result
    rescue => e
      ReactiveActions.logger.error "Error executing action: #{e.message}"
      render json: { success: false, error: e.message }, status: :unprocessable_entity
    end
  end
end