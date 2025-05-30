# frozen_string_literal: true

require 'reactive_actions'

module ReactiveActions
  # Rails engine for the ReactiveActions gem
  # Handles asset inclusion, autoloading, and namespace management
  class Engine < ::Rails::Engine
    isolate_namespace ReactiveActions

    config.generators do |g|
      g.test_framework :rspec
      g.fixture_replacement :factory_bot
      g.factory_bot dir: 'spec/factories'
    end

    # Tell Zeitwerk to ignore the bridge file specifically
    initializer 'reactive_actions.zeitwerk_ignore' do
      Rails.autoloaders.main.ignore("#{root}/lib/reactive-actions.rb")
    end

    # Configure assets for both Sprockets and Propshaft compatibility
    initializer 'reactive_actions.assets' do |app|
      # Add the JavaScript file to asset paths for Propshaft
      app.config.assets.paths << root.join('app/assets/javascripts') if defined?(Propshaft)

      # For Sprockets compatibility (if still being used)
      app.config.assets.precompile += %w[reactive_actions.js] if defined?(Sprockets)
    end

    # Load and namespace action classes properly
    initializer 'reactive_actions.load_actions', after: :load_config_initializers do |app|
      actions_path = "#{app.root}/app/reactive_actions"
      next unless Dir.exist?(actions_path)

      # Find all action files
      Dir.glob("#{actions_path}/**/*_action.rb").each do |file_path|
        # Get relative path and class name
        file_path.sub("#{actions_path}/", '')
        class_name = File.basename(file_path, '.rb').camelize

        # Skip if already defined in ReactiveActions namespace
        next if ReactiveActions.const_defined?(class_name, false)

        begin
          # Load the file to ensure the class is defined
          require_dependency file_path

          # Try to find the class in global namespace
          if Object.const_defined?(class_name, false)
            original_class = Object.const_get(class_name)

            # Create an alias in the ReactiveActions namespace
            ReactiveActions.const_set(class_name, original_class)

            Rails.logger.debug { "ReactiveActions: Aliased #{class_name} to ReactiveActions::#{class_name}" }
          end
        rescue StandardError => e
          Rails.logger.warn "ReactiveActions: Failed to load action #{file_path}: #{e.message}"
        end
      end
    end
  end
end
