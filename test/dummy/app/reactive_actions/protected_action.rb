class ProtectedAction < ReactiveActions::ReactiveAction
  security_check :require_authentication

  def action
    @result = {
      success: true,
      message: "This action requires authentication",
      user: mock_current_user&.dig('name') || "Unknown user"
    }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless mock_current_user
  end

  def mock_current_user
    action_params[:_mock_user_data]&.dig('current_user')
  end
end