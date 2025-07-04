# frozen_string_literal: true

module ReactiveActions
  module Concerns
    # Rate limiting module for ReactiveActions that can be included in actions or other classes
    # Provides convenient methods for checking and managing rate limits
    module RateLimiter
      # Helper method for rate limiting in security checks or actions
      # Automatically respects the global rate_limiting_enabled setting
      # @param key [String, nil] Custom cache key, uses default if nil
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @param cost [Integer] Cost of this request (default: 1)
      # @raise [RateLimitExceededError] When rate limit is exceeded
      def rate_limit!(key: nil, limit: 100, window: 1.hour, cost: 1)
        # Early return if rate limiting is disabled
        return unless ReactiveActions.configuration.rate_limiting_enabled

        effective_key = key || default_rate_limit_key

        ReactiveActions::RateLimiter.check!(
          key: effective_key,
          limit: limit,
          window: window,
          cost: cost
        )
      end

      # Check rate limit without raising an error (also respects configuration)
      # @param key [String, nil] Custom cache key, uses default if nil
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @return [Hash] Rate limit status information
      def rate_limit_status(key: nil, limit: 100, window: 1.hour)
        # Return "unlimited" status if rate limiting is disabled
        unless ReactiveActions.configuration.rate_limiting_enabled
          return {
            limit: Float::INFINITY,
            remaining: Float::INFINITY,
            current: 0,
            window: window,
            exceeded: false,
            enabled: false
          }
        end

        effective_key = key || default_rate_limit_key

        ReactiveActions::RateLimiter.check(
          key: effective_key,
          limit: limit,
          window: window
        ).merge(enabled: true)
      end

      # Reset rate limit for a specific key
      # @param key [String, nil] Custom cache key, uses default if nil
      # @param window [ActiveSupport::Duration] Time window for the limit
      def reset_rate_limit!(key: nil, window: 1.hour)
        return unless ReactiveActions.configuration.rate_limiting_enabled

        effective_key = key || default_rate_limit_key

        ReactiveActions::RateLimiter.reset!(
          key: effective_key,
          window: window
        )
      end

      # Check if rate limiting is currently enabled
      # @return [Boolean] True if rate limiting is enabled
      def rate_limiting_enabled?
        ReactiveActions.configuration.rate_limiting_enabled
      end

      # Get remaining requests for a specific key without consuming any
      # @param key [String, nil] Custom cache key, uses default if nil
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @return [Integer, Float] Number of remaining requests, or Float::INFINITY if disabled
      def rate_limit_remaining(key: nil, limit: 100, window: 1.hour)
        status = rate_limit_status(key: key, limit: limit, window: window)
        status[:remaining]
      end

      # Check if a key would exceed rate limit for a given cost
      # @param key [String, nil] Custom cache key, uses default if nil
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @param cost [Integer] Cost to check (default: 1)
      # @return [Boolean] True if the cost would exceed the limit
      def rate_limit_would_exceed?(key: nil, limit: 100, window: 1.hour, cost: 1)
        return false unless ReactiveActions.configuration.rate_limiting_enabled

        status = rate_limit_status(key: key, limit: limit, window: window)
        status[:remaining] < cost
      end

      # Create a rate limit key for a specific scope
      # @param scope [String, Symbol] The scope (e.g., 'api', 'search', 'upload')
      # @param identifier [String, nil] Custom identifier, uses default if nil
      # @return [String] Formatted rate limit key
      def rate_limit_key_for(scope, identifier: nil)
        base_key = identifier || extract_identifier_from_context
        "#{scope}:#{base_key}"
      end

      # Log rate limiting events for debugging/monitoring
      # @param event [String] Event type (e.g., 'exceeded', 'checked', 'reset')
      # @param details [Hash] Additional details to log
      def log_rate_limit_event(event, details = {})
        return unless ReactiveActions.logger

        ReactiveActions.logger.info(
          "Rate Limit #{event.capitalize}: #{details.merge(key: default_rate_limit_key)}"
        )
      end

      private

      # Default key generation for rate limiting
      # This method tries different approaches to generate a meaningful key
      # @return [String] A rate limit key
      def default_rate_limit_key
        # Try different methods to get a meaningful identifier
        if respond_to?(:current_user) && current_user
          "user:#{current_user.id}"
        elsif respond_to?(:controller) && controller.respond_to?(:request)
          extract_key_from_request(controller.request)
        elsif respond_to?(:request) && request
          extract_key_from_request(request)
        else
          "anonymous:#{SecureRandom.hex(8)}"
        end
      end

      # Extract identifier from current context (user, request, etc.)
      # @return [String] An identifier for the current context
      def extract_identifier_from_context
        if respond_to?(:current_user) && current_user
          current_user.id.to_s
        elsif respond_to?(:controller) && controller.respond_to?(:request)
          controller.request.remote_ip
        elsif respond_to?(:request) && request
          request.remote_ip
        else
          'unknown'
        end
      end

      # Extract a rate limiting key from a request object
      # @param request [ActionDispatch::Request] The request object
      # @return [String] A rate limit key based on the request
      def extract_key_from_request(request)
        # Try to get user info from headers first
        if request.headers['X-User-ID'].present?
          "user:#{request.headers['X-User-ID']}"
        elsif request.headers['Authorization'].present?
          # Extract from API token/key
          auth_header = request.headers['Authorization']
          if auth_header.start_with?('Bearer ')
            token = auth_header.gsub('Bearer ', '')
            "token:#{Digest::SHA256.hexdigest(token)[0..8]}" # Hash for privacy
          else
            "auth:#{request.remote_ip}"
          end
        else
          # Fallback to IP address
          "ip:#{request.remote_ip}"
        end
      end
    end
  end
end
