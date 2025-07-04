# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe Concerns::SecurityChecks, type: :module do
    # Create a test class that includes the SecurityChecks module
    let(:test_class) do
      Class.new do
        include ReactiveActions::Concerns::SecurityChecks

        attr_accessor :action_params, :security_check_called, :other_check_called

        def initialize(action_params = {})
          @action_params = action_params
          @security_check_called = false
          @other_check_called = false
        end

        def test_security_check
          @security_check_called = true
        end

        def other_security_check
          @other_check_called = true
        end

        def failing_security_check
          raise StandardError, 'Security check failed'
        end

        def conditional_method
          action_params[:condition] == 'true'
        end
      end
    end

    let(:test_instance) { test_class.new }

    describe 'class methods' do
      describe '.security_check' do
        it 'adds a security check with method name' do
          test_class.security_check :test_security_check

          expect(test_class.security_filters).to include(
            hash_including(check: :test_security_check)
          )
        end

        it 'adds a security check with lambda' do
          check_lambda = -> { true }
          test_class.security_check check_lambda

          expect(test_class.security_filters).to include(
            hash_including(check: check_lambda)
          )
        end

        it 'adds security check with options' do
          test_class.security_check :test_security_check, only: :action, if: :conditional_method

          expect(test_class.security_filters).to include(
            hash_including(
              check: :test_security_check,
              only: :action,
              if: :conditional_method
            )
          )
        end

        it 'supports multiple security checks' do
          test_class.security_check :test_security_check
          test_class.security_check :other_security_check

          expect(test_class.security_filters.length).to eq(2)
          expect(test_class.security_filters.map { |f| f[:check] }).to include(:test_security_check, :other_security_check)
        end

        it 'preserves existing security filters when adding new ones' do
          test_class.security_check :test_security_check
          original_count = test_class.security_filters.length

          test_class.security_check :other_security_check

          expect(test_class.security_filters.length).to eq(original_count + 1)
        end
      end

      describe '.skip_security_checks' do
        it 'clears all security filters' do
          test_class.security_check :test_security_check
          test_class.security_check :other_security_check

          test_class.skip_security_checks

          expect(test_class.security_filters).to be_empty
        end

        it 'works when no security checks are defined' do
          expect { test_class.skip_security_checks }.not_to raise_error
          expect(test_class.security_filters).to be_empty
        end
      end
    end

    describe 'instance methods' do
      describe '#run_security_checks' do
        before do
          test_class.security_filters = [] # Reset filters
        end

        it 'executes all configured security checks' do
          test_class.security_check :test_security_check
          test_class.security_check :other_security_check

          test_instance.send(:run_security_checks)

          expect(test_instance.security_check_called).to be true
          expect(test_instance.other_check_called).to be true
        end

        it 'executes lambda security checks' do
          lambda_executed = false
          test_class.security_check -> { lambda_executed = true }

          test_instance.send(:run_security_checks)

          expect(lambda_executed).to be true
        end

        it 'does nothing when no security checks are configured' do
          expect { test_instance.send(:run_security_checks) }.not_to raise_error
        end

        it 'skips checks that do not meet conditions' do
          test_class.security_check :test_security_check, if: -> { false }

          test_instance.send(:run_security_checks)

          expect(test_instance.security_check_called).to be false
        end

        it 'converts StandardError to SecurityCheckError' do
          test_class.security_check :failing_security_check

          expect { test_instance.send(:run_security_checks) }.to raise_error(
            ReactiveActions::SecurityCheckError,
            /Security check failed/
          )
        end

        it 'preserves ReactiveActions::Error subclasses' do
          test_class.security_check -> { raise ReactiveActions::UnauthorizedError, 'Not authorized' }

          expect { test_instance.send(:run_security_checks) }.to raise_error(
            ReactiveActions::UnauthorizedError,
            'Not authorized'
          )
        end
      end

      describe '#should_run_security_check?' do
        let(:base_filter) { { check: :test_security_check } }

        context 'with :only condition' do
          it 'runs check when action matches :only condition' do
            filter = base_filter.merge(only: :action)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'runs check when action matches one of multiple :only conditions' do
            filter = base_filter.merge(only: %i[action other_action])

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'skips check when action does not match :only condition' do
            filter = base_filter.merge(only: :other_action)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end
        end

        context 'with :except condition' do
          it 'skips check when action matches :except condition' do
            filter = base_filter.merge(except: :action)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end

          it 'skips check when action matches one of multiple :except conditions' do
            filter = base_filter.merge(except: %i[action other_action])

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end

          it 'runs check when action does not match :except condition' do
            filter = base_filter.merge(except: :other_action)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end
        end

        context 'with :if condition' do
          it 'runs check when :if condition is true (symbol)' do
            test_instance.action_params = { condition: 'true' }
            filter = base_filter.merge(if: :conditional_method)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'skips check when :if condition is false (symbol)' do
            test_instance.action_params = { condition: 'false' }
            filter = base_filter.merge(if: :conditional_method)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end

          it 'runs check when :if condition is true (proc)' do
            filter = base_filter.merge(if: -> { true })

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'skips check when :if condition is false (proc)' do
            filter = base_filter.merge(if: -> { false })

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end
        end

        context 'with :unless condition' do
          it 'skips check when :unless condition is true (symbol)' do
            test_instance.action_params = { condition: 'true' }
            filter = base_filter.merge(unless: :conditional_method)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end

          it 'runs check when :unless condition is false (symbol)' do
            test_instance.action_params = { condition: 'false' }
            filter = base_filter.merge(unless: :conditional_method)

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'skips check when :unless condition is true (proc)' do
            filter = base_filter.merge(unless: -> { true })

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end

          it 'runs check when :unless condition is false (proc)' do
            filter = base_filter.merge(unless: -> { false })

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end
        end

        context 'with multiple conditions' do
          it 'runs check only when all conditions are met' do
            test_instance.action_params = { condition: 'true' }
            filter = base_filter.merge(
              only: :action,
              if: :conditional_method,
              unless: -> { false }
            )

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be true
          end

          it 'skips check when any condition fails' do
            test_instance.action_params = { condition: 'true' }
            filter = base_filter.merge(
              only: :action,
              if: :conditional_method,
              unless: -> { true } # This makes it skip
            )

            result = test_instance.send(:should_run_security_check?, filter)

            expect(result).to be false
          end
        end
      end

      describe '#execute_security_check' do
        it 'executes symbol-based security checks' do
          test_instance.send(:execute_security_check, :test_security_check)

          expect(test_instance.security_check_called).to be true
        end

        it 'executes proc-based security checks' do
          executed = false
          check_proc = -> { executed = true }

          test_instance.send(:execute_security_check, check_proc)

          expect(executed).to be true
        end

        it 'raises SecurityCheckError for invalid check types' do
          expect { test_instance.send(:execute_security_check, 'invalid') }.to raise_error(
            ReactiveActions::SecurityCheckError,
            /Invalid security check/
          )
        end

        it 'converts StandardError to SecurityCheckError' do
          expect { test_instance.send(:execute_security_check, :failing_security_check) }.to raise_error(
            ReactiveActions::SecurityCheckError,
            /Security check failed/
          )
        end

        it 'preserves ReactiveActions::Error instances' do
          security_error_proc = -> { raise ReactiveActions::UnauthorizedError, 'Access denied' }

          expect { test_instance.send(:execute_security_check, security_error_proc) }.to raise_error(
            ReactiveActions::UnauthorizedError,
            'Access denied'
          )
        end
      end

      describe '#evaluate_condition' do
        it 'evaluates proc conditions' do
          result = test_instance.send(:evaluate_condition, -> { true })
          expect(result).to be true

          result = test_instance.send(:evaluate_condition, -> { false })
          expect(result).to be false
        end

        it 'evaluates symbol conditions by calling methods' do
          test_instance.action_params = { condition: 'true' }
          result = test_instance.send(:evaluate_condition, :conditional_method)
          expect(result).to be true

          test_instance.action_params = { condition: 'false' }
          result = test_instance.send(:evaluate_condition, :conditional_method)
          expect(result).to be false
        end

        it 'returns false for invalid condition types' do
          result = test_instance.send(:evaluate_condition, 'invalid')
          expect(result).to be false
        end
      end
    end

    describe 'integration with action classes' do
      # Test User class for verified doubles
      let(:user_class) do
        Class.new do
          attr_accessor :admin

          def initialize(admin: false)
            @admin = admin
          end

          def admin?
            @admin
          end
        end
      end

      let(:action_class) do
        Class.new do
          include ReactiveActions::Concerns::SecurityChecks

          attr_accessor :action_params, :controller

          def initialize(controller = nil, **action_params)
            @controller = controller
            @action_params = action_params
          end

          def authenticate_user!
            raise ReactiveActions::SecurityCheckError, 'Authentication required' unless current_user
          end

          def authorize_admin!
            raise ReactiveActions::SecurityCheckError, 'Admin access required' unless current_user&.admin?
          end

          def current_user
            action_params[:current_user]
          end
        end
      end

      it 'works with realistic authentication checks' do
        action_class.security_check :authenticate_user!
        instance = action_class.new(nil, current_user: { id: 1, name: 'Test User' })

        expect { instance.send(:run_security_checks) }.not_to raise_error
      end

      it 'fails when authentication check fails' do
        action_class.security_check :authenticate_user!
        instance = action_class.new(nil, current_user: nil)

        expect { instance.send(:run_security_checks) }.to raise_error(
          ReactiveActions::SecurityCheckError,
          'Authentication required'
        )
      end

      it 'supports chained security checks' do
        action_class.security_check :authenticate_user!
        action_class.security_check :authorize_admin!

        user = instance_double(user_class, admin?: true)
        instance = action_class.new(nil, current_user: user)

        expect { instance.send(:run_security_checks) }.not_to raise_error
      end

      it 'fails on first failing check in chain' do
        action_class.security_check :authenticate_user!
        action_class.security_check :authorize_admin!

        instance = action_class.new(nil, current_user: nil)

        expect { instance.send(:run_security_checks) }.to raise_error(
          ReactiveActions::SecurityCheckError,
          'Authentication required'
        )
      end

      it 'supports conditional checks based on parameters' do
        action_class.security_check :authenticate_user!
        action_class.security_check :authorize_admin!, if: -> { action_params[:admin_required] }

        # Regular user without admin requirement
        user = instance_double(user_class, admin?: false)
        instance = action_class.new(nil, current_user: user, admin_required: false)
        expect { instance.send(:run_security_checks) }.not_to raise_error

        # Regular user with admin requirement (should fail)
        instance = action_class.new(nil, current_user: user, admin_required: true)
        expect { instance.send(:run_security_checks) }.to raise_error(
          ReactiveActions::SecurityCheckError,
          'Admin access required'
        )
      end
    end

    describe 'inheritance behavior' do
      let(:parent_class) do
        Class.new do
          include ReactiveActions::Concerns::SecurityChecks
          security_check :parent_check

          def parent_check
            # Parent security check
          end
        end
      end

      let(:child_class) do
        Class.new(parent_class) do
          security_check :child_check

          def child_check
            # Child security check
          end
        end
      end

      it 'inherits security checks from parent class' do
        expect(child_class.security_filters.map { |f| f[:check] }).to include(:parent_check, :child_check)
      end

      it 'allows child class to skip all security checks' do
        child_class.skip_security_checks
        expect(child_class.security_filters).to be_empty
      end
    end

    describe 'error handling and logging' do
      let(:logger_spy) { spy }

      before do
        allow(ReactiveActions).to receive(:logger).and_return(logger_spy)
      end

      it 'logs security check failures' do
        test_class.security_check :failing_security_check

        expect { test_instance.send(:run_security_checks) }.to raise_error(ReactiveActions::SecurityCheckError)

        expect(logger_spy).to have_received(:error).with(/Security check failed/)
      end

      it 'includes original error message in SecurityCheckError' do
        test_class.security_check :failing_security_check

        expect { test_instance.send(:run_security_checks) }.to raise_error(
          ReactiveActions::SecurityCheckError,
          /Security check failed: Security check failed/
        )
      end
    end
  end
end
