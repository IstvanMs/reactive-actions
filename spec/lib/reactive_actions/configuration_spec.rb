# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe Configuration, type: :model do
    let(:configuration) { described_class.new }

    describe '#initialize' do
      it 'sets default delegated_controller_methods' do
        expected_methods = %i[
          render redirect_to head params
          session cookies flash request response
        ]

        expect(configuration.delegated_controller_methods).to eq(expected_methods)
      end

      it 'sets default delegated_instance_variables as empty array' do
        expect(configuration.delegated_instance_variables).to eq([])
      end

      it 'sets rate limiting as disabled by default' do
        expect(configuration.rate_limiting_enabled).to be false
      end

      it 'sets global rate limiting as disabled by default' do
        expect(configuration.global_rate_limiting_enabled).to be false
      end

      it 'sets default global rate limit to 600' do
        expect(configuration.global_rate_limit).to eq(600)
      end

      it 'sets default global rate limit window to 1 minute' do
        expect(configuration.global_rate_limit_window).to eq(1.minute)
      end

      it 'sets rate_limit_key_generator to nil by default' do
        expect(configuration.rate_limit_key_generator).to be_nil
      end

      it 'sets rate_limit_cost_calculator to nil by default' do
        expect(configuration.rate_limit_cost_calculator).to be_nil
      end
    end

    describe 'attribute accessors' do
      it 'allows setting and getting delegated_controller_methods' do
        new_methods = %i[custom_method another_method]
        configuration.delegated_controller_methods = new_methods

        expect(configuration.delegated_controller_methods).to eq(new_methods)
      end

      it 'allows setting and getting delegated_instance_variables' do
        new_variables = %i[custom_var another_var]
        configuration.delegated_instance_variables = new_variables

        expect(configuration.delegated_instance_variables).to eq(new_variables)
      end

      it 'allows setting and getting rate_limiting_enabled' do
        configuration.rate_limiting_enabled = true
        expect(configuration.rate_limiting_enabled).to be true

        configuration.rate_limiting_enabled = false
        expect(configuration.rate_limiting_enabled).to be false
      end

      it 'allows setting and getting global_rate_limiting_enabled' do
        configuration.global_rate_limiting_enabled = true
        expect(configuration.global_rate_limiting_enabled).to be true

        configuration.global_rate_limiting_enabled = false
        expect(configuration.global_rate_limiting_enabled).to be false
      end

      it 'allows setting and getting global_rate_limit' do
        configuration.global_rate_limit = 1000
        expect(configuration.global_rate_limit).to eq(1000)
      end

      it 'allows setting and getting global_rate_limit_window' do
        configuration.global_rate_limit_window = 5.minutes
        expect(configuration.global_rate_limit_window).to eq(5.minutes)
      end

      it 'allows setting and getting rate_limit_key_generator' do
        generator = -> { 'custom_key' }
        configuration.rate_limit_key_generator = generator

        expect(configuration.rate_limit_key_generator).to eq(generator)
      end

      it 'allows setting and getting rate_limit_cost_calculator' do
        calculator = -> { 5 }
        configuration.rate_limit_cost_calculator = calculator

        expect(configuration.rate_limit_cost_calculator).to eq(calculator)
      end
    end

    describe '#rate_limiting_available?' do
      context 'when rate limiting is enabled' do
        before { configuration.rate_limiting_enabled = true }

        it 'returns true' do
          expect(configuration.rate_limiting_available?).to be true
        end
      end

      context 'when rate limiting is disabled' do
        before { configuration.rate_limiting_enabled = false }

        it 'returns false' do
          expect(configuration.rate_limiting_available?).to be false
        end
      end
    end

    describe '#global_rate_limiting_active?' do
      context 'when both rate limiting and global rate limiting are enabled' do
        before do
          configuration.rate_limiting_enabled = true
          configuration.global_rate_limiting_enabled = true
        end

        it 'returns true' do
          expect(configuration.global_rate_limiting_active?).to be true
        end
      end

      context 'when rate limiting is enabled but global rate limiting is disabled' do
        before do
          configuration.rate_limiting_enabled = true
          configuration.global_rate_limiting_enabled = false
        end

        it 'returns false' do
          expect(configuration.global_rate_limiting_active?).to be false
        end
      end

      context 'when rate limiting is disabled' do
        before do
          configuration.rate_limiting_enabled = false
          configuration.global_rate_limiting_enabled = true
        end

        it 'returns false' do
          expect(configuration.global_rate_limiting_active?).to be false
        end
      end

      context 'when both are disabled' do
        before do
          configuration.rate_limiting_enabled = false
          configuration.global_rate_limiting_enabled = false
        end

        it 'returns false' do
          expect(configuration.global_rate_limiting_active?).to be false
        end
      end
    end
  end

  RSpec.describe ReactiveActions, '.configuration' do
    after do
      # Reset configuration after each test to avoid test pollution
      described_class.instance_variable_set(:@configuration, nil)
    end

    describe '.configuration' do
      it 'returns a Configuration instance' do
        expect(described_class.configuration).to be_a(ReactiveActions::Configuration)
      end

      it 'returns the same instance on subsequent calls (memoization)' do
        config1 = described_class.configuration
        config2 = described_class.configuration

        expect(config1).to be(config2)
      end

      it 'creates a new instance with default values' do
        config = described_class.configuration

        expect(config.rate_limiting_enabled).to be false
        expect(config.global_rate_limiting_enabled).to be false
        expect(config.global_rate_limit).to eq(600)
      end
    end

    describe '.configuration=' do
      it 'allows setting a custom configuration' do
        custom_config = ReactiveActions::Configuration.new
        custom_config.rate_limiting_enabled = true

        described_class.configuration = custom_config

        expect(described_class.configuration).to be(custom_config)
        expect(described_class.configuration.rate_limiting_enabled).to be true
      end
    end

    describe '.configure' do
      it 'yields the configuration object for block-style setup' do
        expect { |block| described_class.configure(&block) }.to yield_with_args(described_class.configuration)
      end

      it 'allows configuring settings via block' do
        described_class.configure do |config|
          config.rate_limiting_enabled = true
          config.global_rate_limit = 1000
          config.delegated_controller_methods = %i[custom_method]
        end

        config = described_class.configuration
        expect(config.rate_limiting_enabled).to be true
        expect(config.global_rate_limit).to eq(1000)
        expect(config.delegated_controller_methods).to eq(%i[custom_method])
      end

      it 'modifies the existing configuration instance' do
        original_config = described_class.configuration

        described_class.configure do |config|
          config.rate_limiting_enabled = true
        end

        expect(described_class.configuration).to be(original_config)
        expect(described_class.configuration.rate_limiting_enabled).to be true
      end

      it 'allows setting rate limiting configuration' do
        described_class.configure do |config|
          config.rate_limiting_enabled = true
          config.global_rate_limiting_enabled = true
          config.global_rate_limit = 500
          config.global_rate_limit_window = 30.seconds
        end

        config = described_class.configuration
        expect(config.rate_limiting_enabled).to be true
        expect(config.global_rate_limiting_enabled).to be true
        expect(config.global_rate_limit).to eq(500)
        expect(config.global_rate_limit_window).to eq(30.seconds)
      end

      it 'allows setting custom generators and calculators' do
        custom_generator = ->(request, action) { "custom:#{action}:#{request.remote_ip}" }
        custom_calculator = ->(_request, action) { action == 'expensive_action' ? 10 : 1 }

        described_class.configure do |config|
          config.rate_limit_key_generator = custom_generator
          config.rate_limit_cost_calculator = custom_calculator
        end

        config = described_class.configuration
        expect(config.rate_limit_key_generator).to eq(custom_generator)
        expect(config.rate_limit_cost_calculator).to eq(custom_calculator)
      end

      it 'allows setting delegated methods and variables' do
        described_class.configure do |config|
          config.delegated_controller_methods += %i[authorize current_user]
          config.delegated_instance_variables = %i[current_user current_tenant]
        end

        config = described_class.configuration
        expect(config.delegated_controller_methods).to include(:authorize, :current_user)
        expect(config.delegated_instance_variables).to eq(%i[current_user current_tenant])
      end
    end

    describe 'configuration persistence' do
      it 'maintains configuration changes across method calls' do
        described_class.configure do |config|
          config.rate_limiting_enabled = true
          config.global_rate_limit = 2000
        end

        # Access configuration multiple times
        config1 = described_class.configuration
        config2 = described_class.configuration

        expect(config1.rate_limiting_enabled).to be true
        expect(config1.global_rate_limit).to eq(2000)
        expect(config2.rate_limiting_enabled).to be true
        expect(config2.global_rate_limit).to eq(2000)
        expect(config1).to be(config2)
      end
    end

    describe 'integration with helper methods' do
      it 'starts with both rate limiting features disabled' do
        config = described_class.configuration

        expect(config.rate_limiting_available?).to be false
        expect(config.global_rate_limiting_active?).to be false
      end

      it 'shows rate limiting available when enabled' do
        described_class.configure do |c|
          c.rate_limiting_enabled = true
        end

        config = described_class.configuration
        expect(config.rate_limiting_available?).to be true
        expect(config.global_rate_limiting_active?).to be false
      end

      it 'shows global rate limiting active when both flags enabled' do
        described_class.configure do |c|
          c.rate_limiting_enabled = true
          c.global_rate_limiting_enabled = true
        end

        config = described_class.configuration
        expect(config.rate_limiting_available?).to be true
        expect(config.global_rate_limiting_active?).to be true
      end
    end
  end
end
