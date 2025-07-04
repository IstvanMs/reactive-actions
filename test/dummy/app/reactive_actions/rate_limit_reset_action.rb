class RateLimitResetAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    enabled = action_params[:enabled] != false
    
    unless enabled
      @result = {
        success: true,
        enabled: false,
        message: "Rate limiting is disabled - no reset needed"
      }
      return
    end
    
    key = action_params[:key] || 'test_user'
    window = action_params[:window]&.to_i&.seconds || 1.minute
    
    reset_rate_limit!(key: key, window: window)
    
    @result = {
      success: true,
      enabled: true,
      key: key,
      window: window.to_i,
      message: "Rate limit reset successfully"
    }
  end

  def response
    render json: @result
  end
end