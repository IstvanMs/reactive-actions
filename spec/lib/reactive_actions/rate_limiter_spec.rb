# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe RateLimiter, type: :model do
    # Include Rails time helpers for travel_to, travel, etc.
    include ActiveSupport::Testing::TimeHelpers

    let(:cache_key) { 'test_user' }
    let(:limit) { 5 }
    let(:window) { 1.minute }

    before do
      # Clear cache before each test
      Rails.cache.clear
      # Also clear the RateLimiter's internal cache store if it's different
      described_class.send(:cache_store).clear if described_class.send(:cache_store) != Rails.cache
      # Reset the memoized cache store
      described_class.instance_variable_set(:@cache_store, nil)
    end

    describe 'cache store detection' do
      it 'uses MemoryStore when Rails.cache is NullStore' do
        allow(Rails).to receive(:cache).and_return(ActiveSupport::Cache::NullStore.new)
        described_class.instance_variable_set(:@cache_store, nil) # Reset memoization

        cache_store = described_class.send(:cache_store)
        expect(cache_store).to be_a(ActiveSupport::Cache::MemoryStore)
      end

      it 'uses Rails.cache when it is not NullStore' do
        memory_store = ActiveSupport::Cache::MemoryStore.new
        allow(Rails).to receive(:cache).and_return(memory_store)
        described_class.instance_variable_set(:@cache_store, nil) # Reset memoization

        cache_store = described_class.send(:cache_store)
        expect(cache_store).to eq(memory_store)
      end
    end

    describe '.check!' do
      context 'when within rate limit' do
        it 'allows the request and returns rate limit info' do
          freeze_time do
            result = described_class.check!(key: cache_key, limit: limit, window: window)

            expect(result).to include(
              limit: limit,
              remaining: limit - 1,
              current: 1,
              window: window
            )
            expect(result[:key]).to be_present
          end
        end

        it 'increments the counter on subsequent requests' do
          freeze_time do
            # First request
            result1 = described_class.check!(key: cache_key, limit: limit, window: window)
            expect(result1[:current]).to eq(1)
            expect(result1[:remaining]).to eq(4)

            # Second request
            result2 = described_class.check!(key: cache_key, limit: limit, window: window)
            expect(result2[:current]).to eq(2)
            expect(result2[:remaining]).to eq(3)
          end
        end

        it 'handles custom cost parameter' do
          freeze_time do
            result = described_class.check!(key: cache_key, limit: limit, window: window, cost: 3)

            expect(result[:current]).to eq(3)
            expect(result[:remaining]).to eq(2)
          end
        end
      end

      context 'when rate limit is exceeded' do
        it 'raises RateLimitExceededError' do
          freeze_time do
            # Fill up the rate limit
            limit.times do
              described_class.check!(key: cache_key, limit: limit, window: window)
            end

            expect do
              described_class.check!(key: cache_key, limit: limit, window: window)
            end.to raise_error(RateLimitExceededError)

            # Test the error details in a separate expectation
            begin
              described_class.check!(key: cache_key, limit: limit, window: window)
            rescue RateLimitExceededError => e
              expect(e.limit).to eq(limit)
              expect(e.window).to eq(window)
              expect(e.current).to eq(limit)
              expect(e.retry_after).to be > 0
            end
          end
        end

        it 'raises error with custom cost that would exceed limit' do
          freeze_time do
            # Reset and add 3 requests
            Rails.cache.clear
            3.times { described_class.check!(key: cache_key, limit: limit, window: window) }

            expect do
              described_class.check!(key: cache_key, limit: limit, window: window, cost: 3)
            end.to raise_error(RateLimitExceededError)
          end
        end
      end

      context 'with different cache keys' do
        let(:other_key) { 'other_user' }

        it 'maintains separate counters for different keys' do
          freeze_time do
            # Make requests for first key
            3.times { described_class.check!(key: cache_key, limit: limit, window: window) }

            # Make request for different key - should start fresh
            result = described_class.check!(key: other_key, limit: limit, window: window)
            expect(result[:current]).to eq(1)
            expect(result[:remaining]).to eq(4)
          end
        end
      end

      context 'with different time windows' do
        let(:short_window) { 30.seconds }
        let(:long_window) { 5.minutes }

        it 'maintains separate counters for different windows' do
          freeze_time do
            # Make requests with short window
            2.times { described_class.check!(key: cache_key, limit: limit, window: short_window) }

            # Make request with long window - should start fresh
            result = described_class.check!(key: cache_key, limit: limit, window: long_window)
            expect(result[:current]).to eq(1)
            expect(result[:remaining]).to eq(4)
          end
        end
      end
    end

    describe '.check' do
      it 'returns rate limit info without incrementing when within limit' do
        freeze_time do
          # First make a real request
          described_class.check!(key: cache_key, limit: limit, window: window)

          # Check without incrementing
          result = described_class.check(key: cache_key, limit: limit, window: window)

          expect(result).to include(
            limit: limit,
            remaining: limit - 1,
            current: 1,
            window: window,
            exceeded: false
          )
        end
      end

      it 'returns exceeded status when rate limit is exceeded' do
        freeze_time do
          # Fill up the rate limit
          limit.times do
            described_class.check!(key: cache_key, limit: limit, window: window)
          end

          result = described_class.check(key: cache_key, limit: limit, window: window)

          expect(result).to include(
            limit: limit,
            remaining: 0,
            current: limit,
            window: window,
            exceeded: true
          )
          expect(result[:retry_after]).to be > 0
        end
      end

      it 'works when no previous requests have been made' do
        freeze_time do
          result = described_class.check(key: cache_key, limit: limit, window: window)

          expect(result).to include(
            limit: limit,
            remaining: limit,
            current: 0,
            window: window,
            exceeded: false
          )
        end
      end
    end

    describe '.reset!' do
      it 'resets the rate limit counter' do
        freeze_time do
          # Make some requests first
          3.times { described_class.check!(key: cache_key, limit: limit, window: window) }

          described_class.reset!(key: cache_key, window: window)

          result = described_class.check(key: cache_key, limit: limit, window: window)
          expect(result[:current]).to eq(0)
          expect(result[:remaining]).to eq(limit)
        end
      end

      it 'removes both counter and TTL from cache' do
        freeze_time do
          # Make some requests first
          3.times { described_class.check!(key: cache_key, limit: limit, window: window) }

          cache_key_with_window = described_class.send(:build_cache_key, cache_key, window)

          described_class.reset!(key: cache_key, window: window)

          expect(Rails.cache.exist?(cache_key_with_window)).to be false
          expect(Rails.cache.exist?("#{cache_key_with_window}:ttl")).to be false
        end
      end
    end

    describe '.status' do
      it 'returns current status without affecting counters' do
        freeze_time do
          # Make some requests
          2.times { described_class.check!(key: cache_key, limit: limit, window: window) }

          status = described_class.status(key: cache_key, limit: limit, window: window)

          expect(status).to include(
            limit: limit,
            remaining: limit - 2,
            current: 2,
            window: window
          )
          expect(status[:reset_at]).to be_a(Time)

          # Verify counter wasn't incremented
          new_status = described_class.status(key: cache_key, limit: limit, window: window)
          expect(new_status[:current]).to eq(2)
        end
      end

      it 'returns zero current when no requests have been made' do
        freeze_time do
          status = described_class.status(key: cache_key, limit: limit, window: window)

          expect(status).to include(
            limit: limit,
            remaining: limit,
            current: 0,
            window: window
          )
        end
      end
    end

    describe 'private methods' do
      describe '.build_cache_key' do
        it 'builds consistent cache keys for the same time window' do
          freeze_time do
            key1 = described_class.send(:build_cache_key, 'test', 1.minute)
            key2 = described_class.send(:build_cache_key, 'test', 1.minute)

            expect(key1).to eq(key2)
            expect(key1).to include('reactive_actions:rate_limit:test')
          end
        end

        it 'builds different cache keys for different time windows' do
          freeze_time do
            key1 = described_class.send(:build_cache_key, 'test', 1.minute)
            key2 = described_class.send(:build_cache_key, 'test', 5.minutes)

            expect(key1).not_to eq(key2)
          end
        end

        it 'includes window start time and duration in key' do
          freeze_time do
            window_start = (Time.current.to_i / 60) * 60
            key = described_class.send(:build_cache_key, 'test', 1.minute)

            expect(key).to include(window_start.to_s)
            expect(key).to include('60') # 1 minute in seconds
          end
        end
      end
    end

    describe 'cache expiration behavior' do
      it 'automatically expires cache entries after the window' do
        # Start at a specific time
        travel_to Time.zone.parse('2025-01-01 12:00:00') do
          # Make a request
          described_class.check!(key: cache_key, limit: limit, window: 1.second)

          # Verify it exists
          status = described_class.status(key: cache_key, limit: limit, window: 1.second)
          expect(status[:current]).to eq(1)
        end

        # Move to a different time window (more than 1 second later)
        travel_to Time.zone.parse('2025-01-01 12:00:02') do
          # Should be a fresh window now due to different window calculation
          result = described_class.check!(key: cache_key, limit: limit, window: 1.second)
          expect(result[:current]).to eq(1) # Fresh start in new window
        end
      end
    end

    describe 'edge cases' do
      it 'handles zero cost gracefully' do
        freeze_time do
          result = described_class.check!(key: cache_key, limit: limit, window: window, cost: 0)

          expect(result[:current]).to eq(0)
          expect(result[:remaining]).to eq(limit)
        end
      end

      it 'handles very large limits' do
        freeze_time do
          large_limit = 1_000_000
          result = described_class.check!(key: cache_key, limit: large_limit, window: window)

          expect(result[:limit]).to eq(large_limit)
          expect(result[:remaining]).to eq(large_limit - 1)
        end
      end

      it 'handles very short windows' do
        freeze_time do
          short_window = 1.second
          result = described_class.check!(key: cache_key, limit: limit, window: short_window)

          expect(result[:window]).to eq(short_window)
        end
      end

      it 'handles string keys' do
        freeze_time do
          string_key = 'user:123:api'
          result = described_class.check!(key: string_key, limit: limit, window: window)

          expect(result[:current]).to eq(1)
        end
      end
    end

    describe 'concurrent access simulation' do
      it 'handles multiple rapid requests correctly' do
        freeze_time do
          results = []

          # Simulate rapid requests (can't test true concurrency in RSpec easily)
          10.times do
            result = described_class.check!(key: cache_key, limit: limit, window: window)
            results << result
          rescue RateLimitExceededError => e
            results << { error: e.class.name, current: e.current }
          end

          # Should have 5 successful requests and 5 rate limited
          successful = results.reject { |r| r.key?(:error) }
          failed = results.select { |r| r.key?(:error) }

          expect(successful.length).to eq(5)
          expect(failed.length).to eq(5)
          expect(successful.map { |r| r[:current] }).to eq([1, 2, 3, 4, 5])
        end
      end
    end
  end
end
