class RateLimitTestAction < ReactiveActions::ReactiveAction
  include ReactiveActions::Concerns::RateLimiter

  def action
    test_type = action_params[:test_type] || 'basic'
    enabled = action_params[:enabled] != false
    
    # Skip rate limiting if disabled for test
    unless enabled
      @result = {
        success: true,
        message: "Rate limiting disabled for test",
        test_type: test_type,
        enabled: false
      }
      return
    end
    
    # Get test parameters
    key = action_params[:key] || 'test_user'
    limit = action_params[:limit]&.to_i || 5
    window = action_params[:window]&.to_i&.seconds || 1.minute
    cost = action_params[:cost]&.to_i || 1
    
    case test_type
    when 'basic'
      rate_limit!(key: key, limit: limit, window: window)
      @result = {
        success: true,
        message: "Rate limit check passed",
        test_type: test_type,
        key: key,
        limit: limit,
        window: window.to_i
      }
      
    when 'cost'
      rate_limit!(key: key, limit: limit, window: window, cost: cost)
      @result = {
        success: true,
        message: "Rate limit with cost check passed",
        test_type: test_type,
        key: key,
        limit: limit,
        window: window.to_i,
        cost: cost
      }
      
    when 'multiple', 'rapid'
      request_number = action_params[:request_number] || 1
      rate_limit!(key: key, limit: limit, window: window)
      @result = {
        success: true,
        message: "Multiple request #{request_number} passed",
        test_type: test_type,
        request_number: request_number,
        key: key,
        limit: limit
      }
      
    when 'different_key'
      rate_limit!(key: key, limit: limit, window: window)
      @result = {
        success: true,
        message: "Different key test passed",
        test_type: test_type,
        key: key,
        limit: limit
      }
      
    when 'user_based'
      user_id = action_params[:user_id]
      user_key = "user:#{user_id}"
      rate_limit!(key: user_key, limit: limit, window: window)
      @result = {
        success: true,
        message: "User-based rate limit passed",
        test_type: test_type,
        user_id: user_id,
        key: user_key,
        limit: limit
      }
      
    when 'disabled'
      @result = {
        success: true,
        message: "Rate limiting disabled - no checks performed",
        test_type: test_type,
        enabled: false
      }
      
    when 'expiry_setup', 'expiry_test'
      rate_limit!(key: key, limit: limit, window: window)
      @result = {
        success: true,
        message: "Window expiry test step completed",
        test_type: test_type,
        key: key,
        limit: limit,
        window: window.to_i
      }
      
    else
      rate_limit!(key: key, limit: limit, window: window)
      @result = {
        success: true,
        message: "Generic rate limit test passed",
        test_type: test_type,
        key: key,
        limit: limit
      }
    end
  end

  def response
    render json: @result
  end
end