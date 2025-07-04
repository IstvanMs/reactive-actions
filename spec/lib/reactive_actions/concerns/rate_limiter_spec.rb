# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  module Concerns
    RSpec.describe RateLimiter, type: :module do
      # Simple User class for verified doubles
      let(:user_class) do
        Class.new do
          attr_accessor :id

          def initialize(id:)
            @id = id
          end
        end
      end

      # Create a test class that includes the RateLimiter concern
      let(:test_class) do
        Class.new do
          include ReactiveActions::Concerns::RateLimiter

          attr_accessor :action_params, :controller, :request

          def initialize(action_params = {}, controller = nil)
            @action_params = action_params
            @controller = controller
            @request = controller&.request
          end

          def current_user
            action_params[:current_user]
          end

          # Add a request method that can be stubbed
          def request
            @request
          end
        end
      end

      # Use a consistent cache store for all tests
      let(:test_cache_store) { ActiveSupport::Cache::MemoryStore.new }

      before do
        # Enable rate limiting for tests
        ReactiveActions.configuration.rate_limiting_enabled = true

        # Stub the cache_store class method to return our test cache
        # This ensures all rate limiting operations use the same cache instance
        allow(ReactiveActions::RateLimiter).to receive(:cache_store).and_return(test_cache_store)

        # Clear the test cache
        test_cache_store.clear

        # Also clear any class-level memoization
        ReactiveActions::RateLimiter.instance_variable_set(:@cache_store, nil) if ReactiveActions::RateLimiter.instance_variable_defined?(:@cache_store)
      end

      after do
        # Reset rate limiting to default (disabled)
        ReactiveActions.configuration.rate_limiting_enabled = false
        test_cache_store.clear

        # Reset any memoized cache store
        ReactiveActions::RateLimiter.instance_variable_set(:@cache_store, nil) if ReactiveActions::RateLimiter.instance_variable_defined?(:@cache_store)
      end

      describe '#rate_limit!' do
        let(:test_instance) { test_class.new }

        context 'when rate limiting is enabled' do
          it 'successfully checks rate limit within bounds' do
            expect { test_instance.rate_limit!(key: 'test:key', limit: 5, window: 1.minute) }.not_to raise_error
          end

          it 'raises error when rate limit is exceeded' do
            # Use explicit key to ensure consistency
            test_key = 'test:exceeded'

            # Fill up the rate limit
            5.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            expect { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }.to raise_error(
              ReactiveActions::RateLimitExceededError
            )
          end

          it 'uses custom key when provided' do
            custom_key = 'custom:test:key'
            default_key = 'default:test:key'

            # Should not affect default key rate limit
            5.times { test_instance.rate_limit!(key: default_key, limit: 5, window: 1.minute) }

            # Custom key should work fine
            expect { test_instance.rate_limit!(key: custom_key, limit: 5, window: 1.minute) }.not_to raise_error
          end

          it 'handles custom cost parameter' do
            test_key = 'test:cost'
            test_instance.rate_limit!(key: test_key, cost: 3, limit: 5, window: 1.minute)

            # Should only have 2 remaining
            expect { test_instance.rate_limit!(key: test_key, cost: 3, limit: 5, window: 1.minute) }.to raise_error(
              ReactiveActions::RateLimitExceededError
            )
          end
        end

        context 'when rate limiting is disabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = false
          end

          it 'does not perform rate limiting checks' do
            # These would normally exceed the limit, but should work when disabled
            10.times { test_instance.rate_limit!(limit: 2, window: 1.minute) }

            expect { test_instance.rate_limit!(limit: 2, window: 1.minute) }.not_to raise_error
          end
        end
      end

      describe '#rate_limit_status' do
        let(:test_instance) { test_class.new }

        context 'when rate limiting is enabled' do
          it 'returns current rate limit status' do
            test_key = 'test:status'

            # Make some requests
            2.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            status = test_instance.rate_limit_status(key: test_key, limit: 5, window: 1.minute)

            expect(status).to include(
              limit: 5,
              remaining: 3,
              current: 2,
              window: 1.minute,
              enabled: true
            )
          end

          it 'returns fresh status when no requests made' do
            status = test_instance.rate_limit_status(key: 'fresh:test', limit: 10, window: 1.hour)

            expect(status).to include(
              limit: 10,
              remaining: 10,
              current: 0,
              window: 1.hour,
              enabled: true
            )
          end

          it 'uses custom key when provided' do
            custom_key = 'status:test'
            default_key = 'default:status'

            # Make requests with default key
            3.times { test_instance.rate_limit!(key: default_key, limit: 5, window: 1.minute) }

            # Check status with custom key (should be fresh)
            status = test_instance.rate_limit_status(key: custom_key, limit: 5, window: 1.minute)

            expect(status[:current]).to eq(0)
            expect(status[:remaining]).to eq(5)
          end
        end

        context 'when rate limiting is disabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = false
          end

          it 'returns unlimited status' do
            status = test_instance.rate_limit_status(limit: 5, window: 1.minute)

            expect(status).to include(
              limit: Float::INFINITY,
              remaining: Float::INFINITY,
              current: 0,
              enabled: false
            )
          end
        end
      end

      describe '#reset_rate_limit!' do
        let(:test_instance) { test_class.new }

        context 'when rate limiting is enabled' do
          it 'resets the rate limit counter' do
            test_key = 'test:reset'

            # Make some requests
            3.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            # Reset
            test_instance.reset_rate_limit!(key: test_key, window: 1.minute)

            # Should be able to make requests again
            status = test_instance.rate_limit_status(key: test_key, limit: 5, window: 1.minute)
            expect(status[:current]).to eq(0)
            expect(status[:remaining]).to eq(5)
          end

          it 'resets only the specified key' do
            custom_key = 'reset:test'
            default_key = 'default:reset'

            # Make requests with both keys
            2.times { test_instance.rate_limit!(key: default_key, limit: 5, window: 1.minute) }
            2.times { test_instance.rate_limit!(key: custom_key, limit: 5, window: 1.minute) }

            # Reset only custom key
            test_instance.reset_rate_limit!(key: custom_key, window: 1.minute)

            # Default key should still have count
            default_status = test_instance.rate_limit_status(key: default_key, limit: 5, window: 1.minute)
            expect(default_status[:current]).to eq(2)

            # Custom key should be reset
            custom_status = test_instance.rate_limit_status(key: custom_key, limit: 5, window: 1.minute)
            expect(custom_status[:current]).to eq(0)
          end
        end

        context 'when rate limiting is disabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = false
          end

          it 'does nothing when rate limiting is disabled' do
            test_instance = test_class.new
            expect { test_instance.reset_rate_limit!(window: 1.minute) }.not_to raise_error
          end
        end
      end

      describe '#rate_limiting_enabled?' do
        let(:test_instance) { test_class.new }

        it 'returns true when rate limiting is enabled' do
          ReactiveActions.configuration.rate_limiting_enabled = true
          expect(test_instance.rate_limiting_enabled?).to be true
        end

        it 'returns false when rate limiting is disabled' do
          ReactiveActions.configuration.rate_limiting_enabled = false
          expect(test_instance.rate_limiting_enabled?).to be false
        end
      end

      describe '#rate_limit_remaining' do
        let(:test_instance) { test_class.new }

        context 'when rate limiting is enabled' do
          it 'returns remaining requests' do
            test_key = 'test:remaining'

            # Make 2 requests
            2.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            remaining = test_instance.rate_limit_remaining(key: test_key, limit: 5, window: 1.minute)
            expect(remaining).to eq(3)
          end
        end

        context 'when rate limiting is disabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = false
          end

          it 'returns infinity when disabled' do
            test_instance = test_class.new
            remaining = test_instance.rate_limit_remaining(limit: 5, window: 1.minute)
            expect(remaining).to eq(Float::INFINITY)
          end
        end
      end

      describe '#rate_limit_would_exceed?' do
        let(:test_instance) { test_class.new }

        context 'when rate limiting is enabled' do
          it 'returns false when cost would not exceed limit' do
            test_key = 'test:would_exceed_false'

            # Make 2 requests (3 remaining)
            2.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            result = test_instance.rate_limit_would_exceed?(key: test_key, cost: 2, limit: 5, window: 1.minute)
            expect(result).to be false
          end

          it 'returns true when cost would exceed limit' do
            test_key = 'test:would_exceed_true'

            # Make 3 requests (2 remaining)
            3.times { test_instance.rate_limit!(key: test_key, limit: 5, window: 1.minute) }

            result = test_instance.rate_limit_would_exceed?(key: test_key, cost: 3, limit: 5, window: 1.minute)
            expect(result).to be true
          end
        end

        context 'when rate limiting is disabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = false
          end

          it 'always returns false when disabled' do
            test_instance = test_class.new
            result = test_instance.rate_limit_would_exceed?(cost: 1000, limit: 1, window: 1.minute)
            expect(result).to be false
          end
        end
      end

      describe '#rate_limit_key_for' do
        let(:test_instance) { test_class.new }

        it 'creates scoped rate limit keys' do
          key = test_instance.rate_limit_key_for('api')
          expect(key).to start_with('api:')
        end

        it 'uses custom identifier when provided' do
          key = test_instance.rate_limit_key_for('api', identifier: 'user:123')
          expect(key).to eq('api:user:123')
        end

        it 'extracts identifier from context when not provided' do
          # Set up current_user
          user = instance_double(user_class, id: 42)
          test_instance.action_params = { current_user: user }

          key = test_instance.rate_limit_key_for('search')
          expect(key).to eq('search:42')
        end
      end

      describe '#log_rate_limit_event' do
        let(:test_instance) { test_class.new }

        it 'logs rate limiting events' do
          logger_spy = spy
          allow(ReactiveActions).to receive(:logger).and_return(logger_spy)

          test_instance.log_rate_limit_event('exceeded', { limit: 5, current: 6 })

          expect(logger_spy).to have_received(:info).with(
            /Rate Limit Exceeded: .*limit.*5.*current.*6/
          )
        end

        it 'does nothing when logger is not available' do
          test_instance = test_class.new
          allow(ReactiveActions).to receive(:logger).and_return(nil)

          expect { test_instance.log_rate_limit_event('test', {}) }.not_to raise_error
        end
      end

      describe 'default key generation' do
        let(:test_instance) { test_class.new }

        context 'with current_user available' do
          it 'uses user ID for key generation' do
            user = instance_double(user_class, id: 123)
            test_instance.action_params = { current_user: user }

            key = test_instance.send(:default_rate_limit_key)
            expect(key).to eq('user:123')
          end
        end

        context 'with controller and request available' do
          it 'extracts key from request' do
            request = instance_double(ActionDispatch::Request,
                                      remote_ip: '10.0.0.1',
                                      headers: {})
            controller = instance_double(ActionController::Base, request: request)
            test_instance.controller = controller

            key = test_instance.send(:default_rate_limit_key)
            expect(key).to eq('ip:10.0.0.1')
          end

          it 'uses user ID from headers when available' do
            request = instance_double(ActionDispatch::Request,
                                      remote_ip: '10.0.0.1',
                                      headers: { 'X-User-ID' => '456' })
            controller = instance_double(ActionController::Base, request: request)
            test_instance.controller = controller

            key = test_instance.send(:extract_key_from_request, request)
            expect(key).to eq('user:456')
          end

          it 'handles Bearer token in Authorization header' do
            request = instance_double(ActionDispatch::Request,
                                      remote_ip: '10.0.0.1',
                                      headers: { 'Authorization' => 'Bearer abc123def456' })

            key = test_instance.send(:extract_key_from_request, request)
            expect(key).to start_with('token:')
            expect(key.length).to be > 10 # Should include hashed token
          end
        end

        context 'with request directly available' do
          it 'uses request when controller is not available' do
            mock_request = instance_double(ActionDispatch::Request, remote_ip: '192.168.1.1', headers: {})
            test_instance.request = mock_request
            # Properly stub respond_to? method for all possible calls
            # rubocop:disable RSpec/ReceiveMessages
            allow(test_instance).to receive(:respond_to?).and_return(false)
            allow(test_instance).to receive(:respond_to?).with(:current_user).and_return(false)
            allow(test_instance).to receive(:respond_to?).with(:controller).and_return(false)
            allow(test_instance).to receive(:respond_to?).with(:request).and_return(true)
            allow(test_instance).to receive(:respond_to?).with(:request, anything).and_return(true)
            allow(test_instance).to receive(:request).and_return(mock_request)
            # rubocop:enable RSpec/ReceiveMessages

            key = test_instance.send(:default_rate_limit_key)
            expect(key).to eq('ip:192.168.1.1')
          end
        end

        context 'without any context' do
          it 'generates anonymous key' do
            key = test_instance.send(:default_rate_limit_key)
            expect(key).to start_with('anonymous:')
            expect(key.length).to be > 15 # Should include random hex
          end
        end
      end

      describe 'integration with rate limiter service' do
        let(:test_instance) { test_class.new }

        it 'properly delegates to ReactiveActions::RateLimiter' do
          allow(ReactiveActions::RateLimiter).to receive(:check!).and_return(
            limit: 10,
            remaining: 8,
            current: 2,
            window: 5.minutes
          )

          test_instance.rate_limit!(key: 'test:delegate', limit: 10, window: 5.minutes, cost: 2)

          expect(ReactiveActions::RateLimiter).to have_received(:check!).with(
            key: anything,
            limit: 10,
            window: 5.minutes,
            cost: 2
          )
        end

        it 'properly delegates status checks' do
          allow(ReactiveActions::RateLimiter).to receive(:check).and_return(
            limit: 15,
            remaining: 10,
            current: 5,
            window: 1.hour,
            exceeded: false
          )

          status = test_instance.rate_limit_status(limit: 15, window: 1.hour)

          expect(ReactiveActions::RateLimiter).to have_received(:check).with(
            key: anything,
            limit: 15,
            window: 1.hour
          )
          expect(status[:enabled]).to be true
        end
      end

      describe 'with real action context' do
        it 'works within a real action context' do
          action_class = Class.new(ReactiveActions::ReactiveAction) do
            include ReactiveActions::Concerns::RateLimiter

            def action
              # Use rate limiting in action with explicit key to avoid randomness
              rate_limit!(key: 'test:action', limit: 3, window: 1.minute)
              @result = { success: true }
            end

            def response
              render json: @result
            end
          end

          controller = instance_double(ActionController::Base).tap do |ctrl|
            allow(ctrl).to receive(:render)
            allow(ctrl).to receive(:request).and_return(
              instance_double(ActionDispatch::Request, remote_ip: '127.0.0.1', headers: {})
            )
            allow(ctrl).to receive(:instance_exec) do |&block|
              ctrl.instance_eval(&block)
            end
          end

          action = action_class.new(controller, current_user: { id: 999 })

          # Should work first few times
          expect { action.send(:action) }.not_to raise_error
          expect { action.send(:action) }.not_to raise_error
          expect { action.send(:action) }.not_to raise_error

          # Fourth time should fail
          expect { action.send(:action) }.to raise_error(RateLimitExceededError)
        end
      end
    end
  end
end
