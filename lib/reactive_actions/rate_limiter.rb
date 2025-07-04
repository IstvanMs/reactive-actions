# frozen_string_literal: true

module ReactiveActions
  # Core rate limiting class that handles Rails cache operations
  # Provides atomic operations for checking, incrementing, and managing rate limits
  class RateLimiter
    class << self
      # Check if the request is within rate limits
      # @param key [String] The cache key to use for rate limiting
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @param cost [Integer] Cost of this request (default: 1)
      # @return [Hash] Rate limit information
      # @raise [RateLimitExceededError] When rate limit is exceeded
      def check!(key:, limit:, window:, cost: 1)
        cache_key = build_cache_key(key, window)
        current_count = get_current_count(cache_key)

        # Check if this request would exceed the limit
        raise_rate_limit_error(current_count, limit, window, cache_key) if current_count + cost > limit

        # Only increment if cost > 0
        new_count = if cost.positive?
                      increment_cache_counter(cache_key, cost, window)
                    else
                      current_count
                    end

        build_result(new_count, limit, window, cache_key)
      end

      # Check rate limit without raising an error
      # @param key [String] The cache key to use for rate limiting
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @return [Hash] Rate limit information with :exceeded boolean
      def check(key:, limit:, window:)
        cache_key = build_cache_key(key, window)
        current_count = get_current_count(cache_key)

        if current_count >= limit
          ttl = get_ttl(cache_key, window)
          {
            limit: limit,
            remaining: 0,
            current: current_count,
            window: window,
            exceeded: true,
            retry_after: ttl,
            key: cache_key
          }
        else
          {
            limit: limit,
            remaining: limit - current_count,
            current: current_count,
            window: window,
            exceeded: false,
            key: cache_key
          }
        end
      end

      # Reset rate limit for a key
      # @param key [String] The cache key to reset
      # @param window [ActiveSupport::Duration] Time window for the limit
      def reset!(key:, window:)
        cache_key = build_cache_key(key, window)
        cache_store.delete(cache_key)
        cache_store.delete("#{cache_key}:ttl")
      end

      # Get current rate limit status
      # @param key [String] The cache key to check
      # @param limit [Integer] Maximum number of requests allowed
      # @param window [ActiveSupport::Duration] Time window for the limit
      # @return [Hash] Current rate limit status
      def status(key:, limit:, window:)
        cache_key = build_cache_key(key, window)
        current = get_current_count(cache_key)
        ttl = get_ttl(cache_key, window)

        {
          limit: limit,
          remaining: [limit - current, 0].max,
          current: current,
          window: window,
          reset_at: Time.current + ttl.seconds
        }
      end

      private

      # Get the appropriate cache store
      # In test environment with NullStore, use MemoryStore instead
      def cache_store
        @cache_store ||= if Rails.cache.is_a?(ActiveSupport::Cache::NullStore)
                           ActiveSupport::Cache::MemoryStore.new
                         else
                           Rails.cache
                         end
      end

      # Get current count from cache
      def get_current_count(cache_key)
        cache_store.read(cache_key) || 0
      end

      # Get TTL for cache key
      def get_ttl(cache_key, window)
        cache_store.read("#{cache_key}:ttl") || window.to_i
      end

      # Raise rate limit exceeded error
      def raise_rate_limit_error(current_count, limit, window, cache_key)
        remaining_ttl = get_ttl(cache_key, window)
        raise RateLimitExceededError.new(
          limit: limit,
          window: window,
          retry_after: remaining_ttl,
          current: current_count
        )
      end

      # Increment the counter in cache
      def increment_cache_counter(cache_key, cost, window)
        # Try atomic increment first (if supported)
        new_count = cache_store.increment(cache_key, cost)

        if new_count.nil?
          # Key doesn't exist or increment not supported, use read-modify-write
          current = cache_store.read(cache_key) || 0
          new_count = current + cost
          cache_store.write(cache_key, new_count, expires_in: window)

          # Set TTL tracking
          cache_store.write("#{cache_key}:ttl", window.to_i, expires_in: window) unless cache_store.exist?("#{cache_key}:ttl")
        else
          # Increment worked, ensure TTL is set
          cache_store.write("#{cache_key}:ttl", window.to_i, expires_in: window) unless cache_store.exist?("#{cache_key}:ttl")
        end

        new_count
      end

      # Build result hash
      def build_result(count, limit, window, cache_key)
        {
          limit: limit,
          remaining: [limit - count, 0].max,
          current: count,
          window: window,
          key: cache_key
        }
      end

      # Build a cache key that includes the time window
      # This ensures different windows don't interfere with each other
      def build_cache_key(key, window)
        window_start = (Time.current.to_i / window.to_i) * window.to_i
        "reactive_actions:rate_limit:#{key}:#{window_start}:#{window.to_i}"
      end
    end
  end
end
