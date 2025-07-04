class RateLimitStatusAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    enabled = action_params[:enabled] != false
    
    unless enabled
      @result = {
        success: true,
        enabled: false,
        message: "Rate limiting is disabled",
        status: {
          limit: Float::INFINITY,
          remaining: Float::INFINITY,
          current: 0,
          enabled: false
        }
      }
      return
    end
    
    key = action_params[:key] || 'test_user'
    limit = action_params[:limit]&.to_i || 5
    window = action_params[:window]&.to_i&.seconds || 1.minute
    
    status = rate_limit_status(key: key, limit: limit, window: window)
    
    @result = {
      success: true,
      enabled: true,
      key: key,
      status: status
    }
  end

  def response
    render json: @result
  end
end