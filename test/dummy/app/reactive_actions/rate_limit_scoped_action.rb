class RateLimitScopedAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    enabled = action_params[:enabled] != false
    
    unless enabled
      @result = {
        success: true,
        enabled: false,
        message: "Rate limiting is disabled"
      }
      return
    end
    
    scope = action_params[:scope] || 'api'
    identifier = action_params[:identifier] || 'test_user'
    limit = action_params[:limit]&.to_i || 5
    window = action_params[:window]&.to_i&.seconds || 1.minute
    
    scoped_key = rate_limit_key_for(scope, identifier: identifier)
    rate_limit!(key: scoped_key, limit: limit, window: window)
    
    @result = {
      success: true,
      enabled: true,
      scope: scope,
      identifier: identifier,
      scoped_key: scoped_key,
      limit: limit,
      window: window.to_i,
      message: "Scoped rate limit check passed"
    }
  end

  def response
    render json: @result
  end
end