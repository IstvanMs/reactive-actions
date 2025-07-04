# frozen_string_literal: true

module ReactiveActions
  module Concerns
    # Security checks module that provides simple security filtering with function names or lambdas
    module SecurityChecks
      extend ActiveSupport::Concern

      included do
        class_attribute :security_filters, default: []
      end

      class_methods do
        # Add a security check that runs before the action
        #
        # @param check [Symbol, Proc] The method name or lambda to execute
        # @param options [Hash] Conditions for when to run the check
        # @option options [Symbol, Array<Symbol>] :only Run only for these actions
        # @option options [Symbol, Array<Symbol>] :except Skip for these actions
        # @option options [Symbol, Proc] :if Run only if condition is true
        # @option options [Symbol, Proc] :unless Skip if condition is true
        def security_check(check, **options)
          self.security_filters = security_filters + [{ check: check, **options }]
        end

        # Skip all security checks for this action
        def skip_security_checks
          self.security_filters = []
        end
      end

      private

      # Run all configured security checks
      def run_security_checks
        self.class.security_filters.each do |filter_config|
          next unless should_run_security_check?(filter_config)

          execute_security_check(filter_config[:check])
        end
      end

      # Determine if a security check should run based on conditions
      def should_run_security_check?(filter_config)
        return false unless check_only_condition(filter_config[:only])
        return false if check_except_condition(filter_config[:except])
        return false unless check_if_condition(filter_config[:if])
        return false if check_unless_condition(filter_config[:unless])

        true
      end

      def check_only_condition(only_condition)
        return true unless only_condition

        only_actions = Array(only_condition).map(&:to_s)
        only_actions.include?('action')
      end

      def check_except_condition(except_condition)
        return false unless except_condition

        except_actions = Array(except_condition).map(&:to_s)
        except_actions.include?('action')
      end

      def check_if_condition(if_condition)
        return true unless if_condition

        evaluate_condition(if_condition)
      end

      def check_unless_condition(unless_condition)
        return false unless unless_condition

        evaluate_condition(unless_condition)
      end

      def evaluate_condition(condition)
        if condition.is_a?(Proc)
          instance_exec(&condition)
        elsif condition.is_a?(Symbol)
          send(condition)
        else
          false
        end
      end

      # Execute a single security check
      def execute_security_check(check)
        if check.is_a?(Proc)
          instance_exec(&check)
        elsif check.is_a?(Symbol)
          send(check)
        else
          raise ReactiveActions::SecurityCheckError, "Invalid security check: #{check.inspect}"
        end
      rescue ReactiveActions::Error
        # Re-raise ReactiveActions errors as-is
        raise
      rescue StandardError => e
        # Convert other errors to security errors
        ReactiveActions.logger.error "Security check failed in #{self.class.name}: #{e.message}"
        raise ReactiveActions::SecurityCheckError, "Security check failed: #{e.message}"
      end
    end
  end
end
