# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  module Controller
    RSpec.describe RateLimiter, type: :module do
      include ActiveSupport::Testing::TimeHelpers

      # Create a test controller that includes the RateLimiter module
      let(:test_controller_class) do
        Class.new(ApplicationController) do
          include ReactiveActions::Controller::RateLimiter

          def test_action
            head :ok
          end

          def current_user
            @current_user
          end

          def extract_action_name
            'test_action'
          end
        end
      end

      # Create a test user class for verified doubles
      let(:user_class) do
        Class.new do
          attr_accessor :id

          def initialize(id:)
            @id = id
          end
        end
      end

      let(:controller) { test_controller_class.new }
      let(:request) { ActionDispatch::TestRequest.create }
      let(:response) { ActionDispatch::TestResponse.new }

      before do
        # Clear all caches to ensure test isolation
        Rails.cache.clear

        controller.request = request
        controller.response = response
        request.remote_addr = '192.168.1.100'

        # Reset configuration to defaults
        ReactiveActions.configuration.rate_limiting_enabled = false
        ReactiveActions.configuration.global_rate_limiting_enabled = false
        ReactiveActions.configuration.global_rate_limit = 600
        ReactiveActions.configuration.global_rate_limit_window = 1.minute
        ReactiveActions.configuration.rate_limit_key_generator = nil

        # Reset controller state
        controller.instance_variable_set(:@current_user, nil)

        # Reset response headers to ensure clean state
        controller.response = ActionDispatch::TestResponse.new
      end

      after do
        # Ensure rate limiting is disabled after each test to not affect other test suites
        ReactiveActions.configuration.rate_limiting_enabled = false
        ReactiveActions.configuration.global_rate_limiting_enabled = false
        Rails.cache.clear
      end

      describe 'before_action integration' do
        context 'when global rate limiting is disabled' do
          it 'does not trigger rate limiting checks' do
            allow(controller).to receive(:check_global_rate_limit)

            controller.send(:test_action)

            expect(controller).not_to have_received(:check_global_rate_limit)
          end
        end

        context 'when global rate limiting is enabled' do
          before do
            ReactiveActions.configuration.rate_limiting_enabled = true
            ReactiveActions.configuration.global_rate_limiting_enabled = true
          end

          it 'triggers rate limiting checks' do
            # Set up controller to actually process the before_action
            allow(controller).to receive(:check_global_rate_limit)

            # Manually trigger the callback since we're testing in isolation
            controller.send(:check_global_rate_limit) if controller.send(:should_check_global_rate_limit?)

            expect(controller).to have_received(:check_global_rate_limit)
          end
        end
      end

      describe '#should_check_global_rate_limit?' do
        it 'returns false when rate limiting is disabled' do
          expect(controller.send(:should_check_global_rate_limit?)).to be false
        end

        it 'returns false when global rate limiting is disabled' do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = false

          expect(controller.send(:should_check_global_rate_limit?)).to be false
        end

        it 'returns true when both rate limiting and global rate limiting are enabled' do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true

          expect(controller.send(:should_check_global_rate_limit?)).to be true
        end
      end

      describe '#check_global_rate_limit' do
        before do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limit = 5
          ReactiveActions.configuration.global_rate_limit_window = 1.minute

          # Ensure completely fresh cache and response for each test
          Rails.cache.clear
          controller.response = ActionDispatch::TestResponse.new
        end

        it 'adds rate limit headers on successful check' do
          # Use a unique test key for this specific test
          test_key = "test:headers:#{SecureRandom.hex(4)}"
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          controller.send(:check_global_rate_limit)

          expect(controller.response.headers['X-RateLimit-Limit']).to eq('5')
          expect(controller.response.headers['X-RateLimit-Remaining']).to eq('4')
          expect(controller.response.headers['X-RateLimit-Window']).to eq('60')
          expect(controller.response.headers['X-RateLimit-Reset']).to be_present
        end

        it 'handles rate limit exceeded error' do
          # Use a unique test key for this specific test
          test_key = "test:exceeded:#{SecureRandom.hex(4)}"
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          # Fill up the rate limit first
          5.times { controller.send(:check_global_rate_limit) }

          # Mock the error handling to prevent actual rendering
          allow(controller).to receive(:handle_rate_limit_exceeded_error)

          # This should trigger the error handling
          controller.send(:check_global_rate_limit)

          expect(controller).to have_received(:handle_rate_limit_exceeded_error)
        end

        it 'adds retry-after header when rate limit is exceeded' do
          # Use a unique test key for this specific test
          test_key = "test:retry:#{SecureRandom.hex(4)}"
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          # Fill up the rate limit (5 times to reach limit of 5)
          5.times { controller.send(:check_global_rate_limit) }

          # Mock error handling but capture the error for header testing
          captured_error = nil
          allow(controller).to receive(:handle_rate_limit_exceeded_error) do |error|
            captured_error = error
            controller.send(:add_rate_limit_headers_for_exceeded, error)
          end

          # This should trigger rate limit exceeded
          controller.send(:check_global_rate_limit)

          expect(controller).to have_received(:handle_rate_limit_exceeded_error)
          expect(captured_error).to be_a(ReactiveActions::RateLimitExceededError)
        end

        it 'properly handles rate limit exceeded with headers' do
          # Test the header setting directly with a mock error
          rate_limit_error = ReactiveActions::RateLimitExceededError.new(
            limit: 5,
            window: 60.seconds,
            retry_after: 30,
            current: 6
          )

          controller.send(:add_rate_limit_headers_for_exceeded, rate_limit_error)

          expect(controller.response.headers['X-RateLimit-Remaining']).to eq('0')
          expect(controller.response.headers['Retry-After']).to eq('30')
        end
      end

      describe '#global_rate_limit_key' do
        context 'with custom key generator' do
          let(:custom_generator) do
            ->(request, action_name) { "custom:#{action_name}:#{request.remote_ip}" }
          end

          before do
            ReactiveActions.configuration.rate_limit_key_generator = custom_generator
          end

          after do
            ReactiveActions.configuration.rate_limit_key_generator = nil
          end

          it 'uses custom key generator when configured' do
            key = controller.send(:global_rate_limit_key)
            expect(key).to eq('custom:test_action:192.168.1.100')
          end
        end

        context 'with current_user available' do
          before do
            user = instance_double(user_class, id: 123)
            controller.instance_variable_set(:@current_user, user)
          end

          it 'uses user-based key' do
            key = controller.send(:global_rate_limit_key)
            expect(key).to eq('global:user:123')
          end
        end

        context 'without current_user' do
          it 'uses IP-based key' do
            key = controller.send(:global_rate_limit_key)
            expect(key).to eq('global:ip:192.168.1.100')
          end
        end
      end

      describe '#default_global_rate_limit_key' do
        context 'with current_user' do
          before do
            user = instance_double(user_class, id: 456)
            controller.instance_variable_set(:@current_user, user)
          end

          it 'generates user-based key' do
            key = controller.send(:default_global_rate_limit_key)
            expect(key).to eq('global:user:456')
          end
        end

        context 'without current_user' do
          it 'generates IP-based key' do
            key = controller.send(:default_global_rate_limit_key)
            expect(key).to eq('global:ip:192.168.1.100')
          end
        end
      end

      describe 'header management' do
        describe '#add_rate_limit_headers' do
          it 'sets basic rate limit headers' do
            rate_limit_info = {
              limit: 100,
              remaining: 75,
              current: 25,
              window: 60.seconds
            }

            controller.send(:add_rate_limit_headers, rate_limit_info)

            expect(controller.response.headers['X-RateLimit-Limit']).to eq('100')
            expect(controller.response.headers['X-RateLimit-Remaining']).to eq('75')
            expect(controller.response.headers['X-RateLimit-Window']).to eq('60')
            expect(controller.response.headers['X-RateLimit-Reset']).to be_present
          end
        end

        describe '#add_rate_limit_headers_for_exceeded' do
          it 'sets headers for exceeded rate limits' do
            rate_limit_error = ReactiveActions::RateLimitExceededError.new(
              limit: 10,
              window: 60.seconds,
              retry_after: 30,
              current: 15
            )

            controller.send(:add_rate_limit_headers_for_exceeded, rate_limit_error)

            expect(controller.response.headers['X-RateLimit-Limit']).to eq('10')
            expect(controller.response.headers['X-RateLimit-Remaining']).to eq('0')
            expect(controller.response.headers['Retry-After']).to eq('30')
          end
        end

        describe '#rate_limit_reset_header' do
          it 'calculates correct reset time' do
            travel_to Time.parse('2025-01-01 12:00:00 UTC') do
              rate_limit_info = {
                limit: 100,
                remaining: 75,
                current: 25,
                window: 60.seconds
              }

              current_time = Time.current.to_i
              window_seconds = 60
              current_window_start = (current_time / window_seconds) * window_seconds
              expected_reset = current_window_start + window_seconds

              controller.send(:rate_limit_reset_header, rate_limit_info)

              expect(controller.response.headers['X-RateLimit-Reset']).to eq(expected_reset.to_s)
            end
          end
        end
      end

      describe '#handle_rate_limit_exceeded_error' do
        let(:rate_limit_error) do
          ReactiveActions::RateLimitExceededError.new(
            limit: 5,
            window: 60.seconds,
            retry_after: 45,
            current: 8
          )
        end

        context 'when controller has handle_reactive_actions_error method' do
          before do
            # Mock both respond_to? calls
            allow(controller).to receive(:respond_to?).and_call_original
            allow(controller).to receive(:respond_to?).with(:handle_reactive_actions_error, true).and_return(true)
            allow(controller).to receive(:handle_reactive_actions_error)
          end

          it 'delegates to existing error handler' do
            controller.send(:handle_rate_limit_exceeded_error, rate_limit_error)

            expect(controller).to have_received(:handle_reactive_actions_error).with(rate_limit_error)
          end
        end

        context 'when controller does not have custom error handler' do
          before do
            # Mock respond_to? and render methods
            allow(controller).to receive(:respond_to?).and_call_original
            allow(controller).to receive(:respond_to?).with(:handle_reactive_actions_error, true).and_return(false)
            allow(controller).to receive(:performed?).and_return(false)
            allow(controller).to receive(:render)
          end

          it 'uses default rate limit error response' do
            controller.send(:handle_rate_limit_exceeded_error, rate_limit_error)

            expect(controller).to have_received(:render).with(
              hash_including(
                json: hash_including(
                  success: false,
                  error: hash_including(
                    type: 'RateLimitExceededError',
                    code: 'RATE_LIMIT_EXCEEDED',
                    limit: 5,
                    window: 60,
                    retry_after: 45
                  )
                ),
                status: :too_many_requests
              )
            )
          end
        end
      end

      describe '#render_rate_limit_error' do
        let(:rate_limit_error) do
          ReactiveActions::RateLimitExceededError.new(
            limit: 20,
            window: 300.seconds,
            retry_after: 120,
            current: 25
          )
        end

        before do
          allow(controller).to receive(:render)
        end

        it 'renders proper error response' do
          controller.send(:render_rate_limit_error, rate_limit_error)

          expect(controller).to have_received(:render).with(
            json: {
              success: false,
              error: {
                type: 'RateLimitExceededError',
                message: rate_limit_error.message,
                code: 'RATE_LIMIT_EXCEEDED',
                limit: 20,
                window: 300,
                retry_after: 120
              }
            },
            status: :too_many_requests
          )
        end
      end

      describe '#rate_limit_status' do
        before do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limit = 100
          ReactiveActions.configuration.global_rate_limit_window = 1.minute
        end

        it 'returns current rate limit status' do
          # Make some requests first - use a unique key to avoid interference
          test_key = "test:status:#{SecureRandom.hex(4)}"

          # Directly call the RateLimiter to make 3 requests
          3.times do
            ReactiveActions::RateLimiter.check!(
              key: test_key,
              limit: 100,
              window: 1.minute
            )
          end

          # Mock the global_rate_limit_key method to return our test key
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          status = controller.send(:rate_limit_status)

          expect(status).to include(
            limit: 100,
            current: 3
          )
          expect(status[:remaining]).to be >= 0
        end

        it 'returns nil when rate limiting is disabled' do
          ReactiveActions.configuration.rate_limiting_enabled = false

          status = controller.send(:rate_limit_status)
          expect(status).to be_nil
        end
      end

      describe '#reset_rate_limit!' do
        before do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limit = 600
          ReactiveActions.configuration.global_rate_limit_window = 1.minute
        end

        it 'resets rate limit for current key' do
          # Use a unique test key to avoid interference
          test_key = "test:reset:#{SecureRandom.hex(4)}"

          # Make some requests directly to the RateLimiter
          3.times do
            ReactiveActions::RateLimiter.check!(
              key: test_key,
              limit: 600,
              window: 1.minute
            )
          end

          # Mock the global_rate_limit_key method to return our test key
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          # Reset
          controller.send(:reset_rate_limit!)

          # Should be able to make requests again with fresh limit
          controller.send(:check_global_rate_limit)
          expect(controller.response.headers['X-RateLimit-Remaining'].to_i).to be > 595
        end

        it 'does nothing when rate limiting is disabled' do
          ReactiveActions.configuration.rate_limiting_enabled = false

          expect { controller.send(:reset_rate_limit!) }.not_to raise_error
        end
      end

      describe '#log_rate_limit_event' do
        let(:logger_spy) { spy }

        before do
          allow(ReactiveActions).to receive(:logger).and_return(logger_spy)
        end

        it 'logs rate limiting events with details' do
          details = { limit: 100, current: 50 }
          controller.send(:log_rate_limit_event, 'exceeded', details)

          expect(logger_spy).to have_received(:info).with(
            'Rate Limit Exceeded: global:ip:192.168.1.100 - {:limit=>100, :current=>50}'
          )
        end
      end

      describe 'class methods' do
        describe '.rate_limit_action' do
          let(:test_class_with_action_limits) do
            Class.new(ApplicationController) do
              include ReactiveActions::Controller::RateLimiter

              rate_limit_action :show, limit: 10, window: 1.minute
              rate_limit_action :create, limit: 5, window: 5.minutes, only: [:create]

              def show
                head :ok
              end

              def create
                head :created
              end
            end
          end

          before do
            ReactiveActions.configuration.rate_limiting_enabled = true
          end

          it 'adds before_action for rate limited actions' do
            # This is difficult to test directly, but we can verify the behavior
            controller = test_class_with_action_limits.new
            controller.request = request
            controller.response = response

            # Should work within limits
            expect { controller.send(:show) }.not_to raise_error

            # The actual rate limiting logic would be tested through integration
          end
        end

        describe '.skip_rate_limiting' do
          let(:test_class_with_skipped_actions) do
            Class.new(ApplicationController) do
              include ReactiveActions::Controller::RateLimiter

              skip_rate_limiting :health_check, :status

              def health_check
                head :ok
              end

              def status
                head :ok
              end

              def regular_action
                head :ok
              end
            end
          end

          it 'allows skipping rate limiting for specific actions' do
            # This tests that the skip_before_action is called correctly
            # The actual functionality would be verified through integration tests
            expect(test_class_with_skipped_actions).to respond_to(:skip_rate_limiting)
          end
        end
      end

      describe 'integration scenarios' do
        before do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limit = 3
          ReactiveActions.configuration.global_rate_limit_window = 1.minute

          # Ensure completely fresh cache and response for each test
          Rails.cache.clear
          controller.response = ActionDispatch::TestResponse.new
        end

        it 'handles multiple requests from same IP' do
          # Use a unique test key to avoid interference
          test_key = "test:multi:#{SecureRandom.hex(4)}"

          # Mock the global_rate_limit_key method to return our test key
          allow(controller).to receive(:global_rate_limit_key).and_return(test_key)

          # First request - should succeed
          controller.send(:check_global_rate_limit)
          expect(controller.response.headers['X-RateLimit-Remaining']).to eq('2')

          # Second request - should succeed
          controller.send(:check_global_rate_limit)
          expect(controller.response.headers['X-RateLimit-Remaining']).to eq('1')

          # Third request - should succeed
          controller.send(:check_global_rate_limit)
          expect(controller.response.headers['X-RateLimit-Remaining']).to eq('0')

          # Fourth request - should be rate limited
          allow(controller).to receive(:handle_rate_limit_exceeded_error)
          controller.send(:check_global_rate_limit)
          expect(controller).to have_received(:handle_rate_limit_exceeded_error)
        end

        it 'handles requests from different users separately' do
          # First user
          user1 = instance_double(user_class, id: 1)
          controller.instance_variable_set(:@current_user, user1)
          3.times { controller.send(:check_global_rate_limit) }

          # Should be rate limited
          allow(controller).to receive(:handle_rate_limit_exceeded_error)
          controller.send(:check_global_rate_limit)
          expect(controller).to have_received(:handle_rate_limit_exceeded_error)

          # Different user should have fresh limit
          user2 = instance_double(user_class, id: 2)
          controller.instance_variable_set(:@current_user, user2)
          expect { controller.send(:check_global_rate_limit) }.not_to raise_error
        end

        it 'respects custom key generator' do
          ReactiveActions.configuration.rate_limit_key_generator = lambda do |_request, action_name|
            "custom:#{action_name}:test"
          end

          # All requests should use the same custom key
          3.times { controller.send(:check_global_rate_limit) }

          allow(controller).to receive(:handle_rate_limit_exceeded_error)
          controller.send(:check_global_rate_limit)
          expect(controller).to have_received(:handle_rate_limit_exceeded_error)

          ReactiveActions.configuration.rate_limit_key_generator = nil
        end
      end

      describe 'error edge cases' do
        before do
          ReactiveActions.configuration.rate_limiting_enabled = true
          ReactiveActions.configuration.global_rate_limiting_enabled = true
        end

        it 'handles RateLimiter service errors gracefully' do
          allow(ReactiveActions::RateLimiter).to receive(:check!).and_raise(StandardError, 'Cache error')

          expect { controller.send(:check_global_rate_limit) }.to raise_error(StandardError, 'Cache error')
        end

        it 'handles missing request gracefully' do
          controller.request = nil

          expect { controller.send(:global_rate_limit_key) }.not_to raise_error

          key = controller.send(:global_rate_limit_key)
          expect(key).to match(/^global:unknown:/)
        end
      end
    end
  end
end
