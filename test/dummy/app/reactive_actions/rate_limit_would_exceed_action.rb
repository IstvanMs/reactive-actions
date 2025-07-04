class RateLimitWouldExceedAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    enabled = action_params[:enabled] != false
    
    unless enabled
      @result = {
        success: true,
        enabled: false,
        would_exceed: false,
        message: "Rate limiting is disabled"
      }
      return
    end
    
    key = action_params[:key] || 'test_user'
    limit = action_params[:limit]&.to_i || 5
    window = action_params[:window]&.to_i&.seconds || 1.minute
    cost = action_params[:cost]&.to_i || 1
    
    would_exceed = rate_limit_would_exceed?(key: key, limit: limit, window: window, cost: cost)
    
    @result = {
      success: true,
      enabled: true,
      key: key,
      cost: cost,
      limit: limit,
      window: window.to_i,
      would_exceed: would_exceed,
      message: would_exceed ? "Request would exceed limit" : "Request within limit"
    }
  end

  def response
    render json: @result
  end
end