# frozen_string_literal: true

module ReactiveActions
  module Controller
    # Controller module that adds rate limiting functionality
    # Include this module in any controller that needs rate limiting
    module RateLimiter
      extend ActiveSupport::Concern

      included do
        # Add rate limiting before_action ONLY if enabled
        before_action :check_global_rate_limit, if: :should_check_global_rate_limit?
      end

      private

      # Determine if global rate limiting should be checked
      def should_check_global_rate_limit?
        ReactiveActions.configuration.global_rate_limiting_active?
      end

      # Main rate limiting check method
      def check_global_rate_limit
        # Double-check that rate limiting is enabled (safety measure)
        return unless ReactiveActions.configuration.rate_limiting_enabled

        rate_limit_info = ReactiveActions::RateLimiter.check!(
          key: global_rate_limit_key,
          limit: ReactiveActions.configuration.global_rate_limit,
          window: ReactiveActions.configuration.global_rate_limit_window
        )

        # Add rate limit headers to response
        add_rate_limit_headers(rate_limit_info)
      rescue ReactiveActions::RateLimitExceededError => e
        add_rate_limit_headers_for_exceeded(e)
        handle_rate_limit_exceeded_error(e)
      end

      # Generate the cache key for global rate limiting
      def global_rate_limit_key
        # Use the configured key generator or default logic
        if ReactiveActions.configuration.rate_limit_key_generator
          action_name = respond_to?(:extract_action_name, true) ? extract_action_name : 'unknown'
          ReactiveActions.configuration.rate_limit_key_generator.call(request, action_name)
        else
          default_global_rate_limit_key
        end
      end

      # Default key generation strategy
      def default_global_rate_limit_key
        # Prefer user-based limiting if available, fallback to IP
        if respond_to?(:current_user, true) && current_user
          "global:user:#{current_user.id}"
        elsif request.respond_to?(:remote_ip)
          "global:ip:#{request.remote_ip}"
        else
          "global:unknown:#{SecureRandom.hex(8)}"
        end
      end

      # Add rate limit headers to successful responses
      def add_rate_limit_headers(rate_limit_info)
        rate_limit_basic_headers(rate_limit_info)
        rate_limit_reset_header(rate_limit_info)
      end

      # Add rate limit headers for exceeded limits
      def add_rate_limit_headers_for_exceeded(error)
        rate_limit_exceeded_headers(error)
        rate_limit_retry_after_header(error)
      end

      # Set basic rate limit headers
      def rate_limit_basic_headers(rate_limit_info)
        response.headers['X-RateLimit-Limit'] = rate_limit_info[:limit].to_s
        response.headers['X-RateLimit-Remaining'] = rate_limit_info[:remaining].to_s
        response.headers['X-RateLimit-Window'] = rate_limit_info[:window].to_i.to_s
      end

      # Set rate limit reset header based on window
      def rate_limit_reset_header(rate_limit_info)
        window_seconds = rate_limit_info[:window].to_i
        current_window_start = (Time.current.to_i / window_seconds) * window_seconds
        reset_time = current_window_start + window_seconds
        response.headers['X-RateLimit-Reset'] = reset_time.to_s
      end

      # Set headers for exceeded rate limits
      def rate_limit_exceeded_headers(error)
        response.headers['X-RateLimit-Limit'] = error.limit.to_s
        response.headers['X-RateLimit-Remaining'] = '0'
        response.headers['X-RateLimit-Window'] = error.window.to_i.to_s
        response.headers['X-RateLimit-Reset'] = (Time.current + error.retry_after).to_i.to_s
      end

      # Set retry after header
      def rate_limit_retry_after_header(error)
        response.headers['Retry-After'] = error.retry_after.to_s
      end

      # Handle rate limit exceeded errors
      # Override this method in your controller if you need custom handling
      def handle_rate_limit_exceeded_error(error)
        # Check if the including controller has its own error handling
        if respond_to?(:handle_reactive_actions_error, true)
          handle_reactive_actions_error(error)
        else
          # Default rate limit error response - only render if not already rendered
          render_rate_limit_error(error) unless performed?
        end
      end

      # Default rate limit error rendering
      def render_rate_limit_error(error)
        render json: {
          success: false,
          error: {
            type: 'RateLimitExceededError',
            message: error.message,
            code: 'RATE_LIMIT_EXCEEDED',
            limit: error.limit,
            window: error.window.to_i,
            retry_after: error.retry_after
          }
        }, status: :too_many_requests
      end

      # Get current rate limit status without consuming a request
      def rate_limit_status
        return nil unless ReactiveActions.configuration.rate_limiting_enabled

        ReactiveActions::RateLimiter.status(
          key: global_rate_limit_key,
          limit: ReactiveActions.configuration.global_rate_limit,
          window: ReactiveActions.configuration.global_rate_limit_window
        )
      end

      # Reset rate limit for current key (useful for testing or admin overrides)
      def reset_rate_limit!
        return unless ReactiveActions.configuration.rate_limiting_enabled

        ReactiveActions::RateLimiter.reset!(
          key: global_rate_limit_key,
          window: ReactiveActions.configuration.global_rate_limit_window
        )
      end

      # Helper method to log rate limiting events
      def log_rate_limit_event(event_type, details = {})
        ReactiveActions.logger.info(
          "Rate Limit #{event_type.to_s.capitalize}: #{global_rate_limit_key} - #{details}"
        )
      end

      # Class methods for the RateLimiter module
      module ClassMethods
        # Configure rate limiting for specific actions
        # Example: rate_limit_action :show, limit: 100, window: 1.minute
        def rate_limit_action(action_name, limit:, window:, **options)
          before_action(**options) do
            next unless ReactiveActions.configuration.rate_limiting_enabled

            rate_limit_info = ReactiveActions::RateLimiter.check!(
              key: "action:#{action_name}:#{global_rate_limit_key}",
              limit: limit,
              window: window
            )

            add_rate_limit_headers(rate_limit_info)
          rescue ReactiveActions::RateLimitExceededError => e
            add_rate_limit_headers_for_exceeded(e)
            handle_rate_limit_exceeded_error(e)
          end
        end

        # Skip rate limiting for specific actions
        # Example: skip_rate_limiting :health_check, :status
        def skip_rate_limiting(*action_names)
          skip_before_action :check_global_rate_limit, only: action_names
        end
      end
    end
  end
end
