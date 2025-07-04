class AdminAction < ReactiveActions::ReactiveAction
  security_check :require_authentication
  security_check :require_admin_role

  def action
    @result = {
      success: true,
      message: "Admin-only action executed successfully",
      admin_data: "Secret admin information"
    }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Please log in" unless mock_current_user
  end

  def require_admin_role
    unless mock_current_user&.dig('admin')
      raise ReactiveActions::SecurityCheckError, "Admin access required"
    end
  end

  def mock_current_user
    action_params[:_mock_user_data]&.dig('current_user')
  end
end