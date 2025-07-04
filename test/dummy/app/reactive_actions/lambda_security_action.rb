class LambdaSecurityAction < ReactiveActions::ReactiveAction
  security_check -> {
    mock_user = action_params[:_mock_user_data]&.dig('current_user')
    raise ReactiveActions::SecurityCheckError, "Must be logged in" unless mock_user
    
    if action_params[:user_id].present?
      unless mock_user['id'].to_s == action_params[:user_id].to_s
        raise ReactiveActions::SecurityCheckError, "Can only access your own data"
      end
    end
  }

  def action
    @result = {
      success: true,
      message: "Lambda security check passed",
      user_id: action_params[:user_id]
    }
  end

  def response
    render json: @result
  end
end