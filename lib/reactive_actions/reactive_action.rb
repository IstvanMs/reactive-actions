# frozen_string_literal: true

module ReactiveActions
  # Base class for reactive actions
  # Provides common functionality for executing actions and handling responses
  class ReactiveAction
    attr_reader :action_params, :result, :controller

    # Initialize a new reactive action
    #
    # @param [ActionController::Base] controller The controller instance
    # @param [Hash] action_params Parameters to be used in the action
    def initialize(controller = nil, **action_params)
      @controller = controller
      @action_params = action_params

      # Delegate instance variables from controller to actions class
      ReactiveActions.configuration.delegated_instance_variables.each do |instance_variable|
        instance_variable_set("@#{instance_variable}", controller.instance_variable_get("@#{instance_variable}"))
      end
    end

    # Execute the action and handle the response through the controller
    def run
      ReactiveActions.logger.info "Running action #{self.class.name} with params: #{action_params.inspect}"

      begin
        # Run the action
        controller.instance_exec(&method(:action))
        # Run the response
        controller.instance_exec(&method(:response))
      rescue ReactiveActions::Error => e
        # Let ReactiveActions errors bubble up without modification
        raise e
      rescue StandardError => e
        # Modify all other errors
        ReactiveActions.logger.error "Error in action #{self.class.name}: #{e.message}"
        raise ReactiveActions::ActionExecutionError, "Error executing #{self.class.name}: #{e.message}"
      end
    end

    # The action to be implemented by subclasses
    def action
      raise NotImplementedError, "#{self.class.name} must implement the 'action' method"
    end

    # The response to be implemented by subclasses
    def response
      controller.head :ok
    end

    # Make class methods private
    class << self
      # This hook runs when ReactiveAction is subclassed
      def inherited(subclass)
        # Call super
        super
        # Apply controller method delegations from configuration
        ReactiveActions.configuration.delegated_controller_methods.each do |method_name|
          subclass.delegate method_name, to: :controller, allow_nil: true if ActionController::Base.instance_methods.include?(method_name.to_sym)
        end
      end

      private :inherited
    end
  end
end
