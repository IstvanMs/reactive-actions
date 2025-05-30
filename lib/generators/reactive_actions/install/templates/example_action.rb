# frozen_string_literal: true

# Example reactive action
# This action demonstrates the basic structure of a reactive action
class ExampleAction < ReactiveActions::ReactiveAction
  # The main action logic goes here
  def action
    # You can access action parameters via the action_params
    name = action_params[:name] || 'World'

    # Generate a result hash (optional)
    @result = {
      status: :success,
      message: "Hello, #{name}!"
    }
  end

  # Define how to respond to the client
  def response
    # You can use controller methods like render
    render json: {
      success: true,
      data: @result
    }
  end
end
