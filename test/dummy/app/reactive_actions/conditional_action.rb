class ConditionalAction < ReactiveActions::ReactiveAction
  security_check :require_authentication
  security_check :require_special_access, if: -> { action_params[:special] == "true" }

  def action
    @result = {
      success: true,
      message: "Conditional security checks passed",
      special_mode: action_params[:special] == "true"
    }
  end

  def response
    render json: @result
  end

  private

  def require_authentication
    raise ReactiveActions::SecurityCheckError, "Authentication required" unless mock_current_user
  end

  def require_special_access
    unless mock_current_user&.dig('special_access')
      raise ReactiveActions::SecurityCheckError, "Special access required"
    end
  end

  def mock_current_user
    action_params[:_mock_user_data]&.dig('current_user')
  end
end
