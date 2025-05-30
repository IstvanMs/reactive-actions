# frozen_string_literal: true

module ReactiveActions
  # Base controller for the ReactiveActions engine
  # Provides common functionality and settings for all controllers in the engine
  class ApplicationController < ActionController::Base
    # This controller is the base controller for all controllers in the engine
    protect_from_forgery with: :exception
  end
end
