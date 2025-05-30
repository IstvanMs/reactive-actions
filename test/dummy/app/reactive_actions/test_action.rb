class TestAction < ReactiveActions::ReactiveAction
  def action
    @from_action = true
  end

  def response
    render json: { 
      success: true,
      action_class: self.class,
      from_action: @from_action
    }, status: :ok
  end
end