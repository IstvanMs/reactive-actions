# frozen_string_literal: true

require "reactive_actions/version"
require "reactive_actions/engine"

module ReactiveActions
  # Your code goes here...
  
  class << self
    attr_writer :logger
    
    def logger
      @logger ||= Rails.logger
    end
  end
end