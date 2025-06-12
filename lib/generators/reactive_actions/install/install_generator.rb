# frozen_string_literal: true

require 'rails/generators'

module ReactiveActions
  module Generators
    # Interactive generator for installing ReactiveActions into a Rails application
    # Prompts user for installation preferences and customization options
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)

      desc 'Installs ReactiveActions with interactive configuration'

      # Command line options
      class_option :skip_routes, type: :boolean, default: false,
                                 desc: 'Skip adding routes to the application'
      class_option :skip_javascript, type: :boolean, default: false,
                                     desc: 'Skip adding JavaScript imports'
      class_option :skip_example, type: :boolean, default: false,
                                  desc: 'Skip generating example action'
      class_option :mount_path, type: :string, default: '/reactive_actions',
                                desc: 'Custom mount path for ReactiveActions'
      class_option :auto_initialize, type: :boolean, default: true,
                                     desc: 'Auto-initialize ReactiveActions client on page load'
      class_option :enable_dom_binding, type: :boolean, default: true,
                                        desc: 'Enable automatic DOM binding'
      class_option :enable_mutation_observer, type: :boolean, default: true,
                                              desc: 'Enable mutation observer for dynamic content'
      class_option :default_http_method, type: :string, default: 'POST',
                                         desc: 'Default HTTP method for actions'
      class_option :quiet, type: :boolean, default: false,
                           desc: 'Run with minimal output'

      def welcome_message
        return if options[:quiet]

        say 'Welcome to ReactiveActions installer!', :green
        say 'This will help you set up ReactiveActions in your Rails application.'
        say ''
      end

      def create_initializer
        if options[:quiet] || yes?('Create ReactiveActions initializer? (recommended)', :green)
          template 'initializer.rb', 'config/initializers/reactive_actions.rb'
          say '✓ Created initializer', :green unless options[:quiet]
        else
          say '✗ Skipped initializer creation', :yellow
        end
      end

      def create_actions_directory
        if options[:quiet] || yes?('Create app/reactive_actions directory?', :green)
          empty_directory 'app/reactive_actions'
          say '✓ Created actions directory', :green unless options[:quiet]

          ask_for_example_action unless options[:skip_example]
        else
          say '✗ Skipped actions directory creation', :yellow
        end
      end

      def configure_routes
        return if options[:skip_routes]

        mount_path = determine_mount_path
        return if mount_path.nil?

        route "mount ReactiveActions::Engine, at: '#{mount_path}'"
        say "✓ Added route mounting ReactiveActions at #{mount_path}", :green unless options[:quiet]
      end

      def configure_javascript
        return if options[:skip_javascript]
        return unless javascript_needed?

        if options[:quiet] || yes?('Add ReactiveActions JavaScript client?', :green)
          add_javascript_to_importmap
          add_javascript_initialization
          say '✓ Added JavaScript client with initialization', :green unless options[:quiet]
        else
          say '✗ Skipped JavaScript configuration', :yellow
        end
      end

      def javascript_configuration_options
        return if options[:skip_javascript] || options[:quiet]
        return unless javascript_needed?

        configure_javascript_options
      end

      def configuration_options
        return if options[:quiet]
        return unless yes?('Configure advanced options?', :green)

        configure_delegated_methods
        configure_logging
      end

      def installation_summary
        return if options[:quiet]

        say '', :green
        say '=' * 60, :green
        say 'ReactiveActions installation complete!', :bold
        say '=' * 60, :green

        show_usage_instructions
      end

      private

      def should_skip_example_action?
        return true if options[:skip_example]
        return true if !options[:quiet] && !yes?('Generate example action file?', :green)

        false
      end

      def example_action_name
        if options[:quiet]
          'example'
        else
          ask('What should the example action be called?', default: 'example')
        end
      end

      def sanitize_action_name(action_name)
        sanitized = action_name.to_s.strip.underscore
        sanitized = 'example' if sanitized.blank?
        sanitized.end_with?('_action') ? sanitized : "#{sanitized}_action"
      end

      def determine_mount_path
        return options[:mount_path] if options[:quiet]
        return nil if options[:skip_routes]

        if yes?('Add ReactiveActions routes to your application?', :green)
          custom_path = ask('Mount path for ReactiveActions:', default: options[:mount_path])
          sanitize_mount_path(custom_path)
        else
          say '✗ Skipped route configuration', :yellow
          nil
        end
      end

      def sanitize_mount_path(path)
        sanitized = path.to_s.strip
        sanitized = options[:mount_path] if sanitized.blank?
        sanitized.start_with?('/') ? sanitized : "/#{sanitized}"
      end

      def javascript_needed?
        using_importmap? || using_sprockets?
      end

      def using_importmap?
        File.exist?('config/importmap.rb')
      end

      def using_sprockets?
        File.exist?('app/assets/config/manifest.js')
      end

      def add_javascript_to_importmap
        if using_importmap?
          add_to_importmap
        elsif using_sprockets?
          add_to_sprockets_manifest
        else
          say 'No supported JavaScript setup detected (importmap or sprockets)', :yellow
        end
      end

      def add_to_importmap
        importmap_content = <<~IMPORTMAP

          # ReactiveActions JavaScript client
          pin "reactive_actions", to: "reactive_actions.js"
        IMPORTMAP

        append_to_file 'config/importmap.rb', importmap_content
      end

      def add_javascript_initialization
        app_js_paths = %w[
          app/javascript/application.js
          app/assets/javascripts/application.js
          app/javascript/controllers/application.js
        ]

        app_js_path = app_js_paths.find { |path| File.exist?(path) }

        if app_js_path
          # Check if ReactiveActions is already configured
          app_js_content = File.read(app_js_path)
          return if app_js_content.include?('ReactiveActions') || app_js_content.include?('reactive_actions')

          # Generate JavaScript initialization code
          js_config = generate_javascript_config

          js_code = <<~JAVASCRIPT

            // Import and initialize ReactiveActions
            import ReactiveActionsClient from "reactive_actions"

            // Create and configure ReactiveActions instance
            const reactiveActions = new ReactiveActionsClient(#{js_config});

            #{generate_initialization_code}

            // Make ReactiveActions globally available
            window.ReactiveActions = reactiveActions;
          JAVASCRIPT

          append_to_file app_js_path, js_code
          say "✓ Added ReactiveActions initialization to #{app_js_path}", :green unless options[:quiet]
        else
          say '⚠ Could not find application.js file. Please manually add ReactiveActions initialization.', :yellow
        end
      end

      def generate_javascript_config
        config = {}

        # Add mount path if different from default
        mount_path = determine_mount_path || options[:mount_path]
        config[:baseUrl] = "#{mount_path}/execute" if mount_path != '/reactive_actions'

        # Add configuration options
        config[:enableAutoBinding] = javascript_option_value(:enable_dom_binding)
        config[:enableMutationObserver] = javascript_option_value(:enable_mutation_observer)
        config[:defaultHttpMethod] = javascript_option_value(:default_http_method, 'POST')

        # Remove default values to keep config clean
        config.delete(:enableAutoBinding) if config[:enableAutoBinding] == true
        config.delete(:enableMutationObserver) if config[:enableMutationObserver] == true
        config.delete(:defaultHttpMethod) if config[:defaultHttpMethod] == 'POST'

        config.empty? ? '{}' : JSON.pretty_generate(config)
      end

      def generate_initialization_code
        if javascript_option_value(:auto_initialize)
          <<~JAVASCRIPT.strip
            // Initialize on DOM content loaded and Turbo events
            document.addEventListener('DOMContentLoaded', () => reactiveActions.initialize());
            document.addEventListener('turbo:load', () => reactiveActions.initialize());
            document.addEventListener('turbo:frame-load', () => reactiveActions.initialize());
          JAVASCRIPT
        else
          <<~JAVASCRIPT.strip
            // Manual initialization - call reactiveActions.initialize() when ready
            // Example: reactiveActions.initialize();
          JAVASCRIPT
        end
      end

      def javascript_option_value(option_key, default_value = nil)
        return options[option_key] if options.key?(option_key)
        return default_value unless default_value.nil?

        case option_key
        when :enable_dom_binding, :enable_mutation_observer, :auto_initialize
          true
        when :default_http_method
          'POST'
        end
      end

      def configure_javascript_options
        return unless yes?('Configure JavaScript client options?', :green)

        # Auto-initialize option
        auto_init = yes?('Auto-initialize ReactiveActions on page load? (recommended)', :green)
        @javascript_options ||= {}
        @javascript_options[:auto_initialize] = auto_init

        # DOM binding option
        enable_dom = yes?('Enable automatic DOM binding? (recommended)', :green)
        @javascript_options[:enable_dom_binding] = enable_dom

        # Mutation observer option
        if enable_dom
          enable_observer = yes?('Enable mutation observer for dynamic content? (recommended)', :green)
          @javascript_options[:enable_mutation_observer] = enable_observer
        end

        # Default HTTP method
        http_methods = %w[POST GET PUT PATCH DELETE]
        default_method = ask('Default HTTP method:', limited_to: http_methods, default: 'POST')
        @javascript_options[:default_http_method] = default_method unless default_method == 'POST'
      end

      def add_to_sprockets_manifest
        return unless File.exist?('app/assets/config/manifest.js')

        append_to_file 'app/assets/config/manifest.js' do
          "\n//= link reactive_actions.js\n"
        end
      end

      def configure_delegated_methods
        return unless yes?('Add custom controller methods to delegate to actions?', :green)

        methods = ask('Enter method names (comma-separated):')
        return if methods.blank?

        method_array = methods.split(',').map(&:strip).map(&:to_sym)
        add_custom_config('delegated_controller_methods', method_array)
      end

      def configure_logging
        log_level = ask('Set logging level:',
                        limited_to: %w[debug info warn error fatal],
                        default: 'info')

        add_custom_config('log_level', log_level) unless log_level == 'info'
      end

      def add_custom_config(option, value)
        initializer_path = 'config/initializers/reactive_actions.rb'
        return unless File.exist?(initializer_path)

        config_line = build_config_line(option, value)
        append_to_file initializer_path, "\n#{config_line}\n"
      end

      def build_config_line(option, value)
        case option
        when 'delegated_controller_methods'
          "  config.delegated_controller_methods += #{value}"
        when 'log_level'
          "ReactiveActions.logger.level = :#{value}"
        end
      end

      def show_usage_instructions
        if yes?('Show usage instructions?', :green)
          readme 'README' if behavior == :invoke
        else
          say 'You can find usage instructions in the ReactiveActions documentation.'
        end
      end

      def ask_for_example_action
        return if should_skip_example_action?

        action_name = example_action_name
        sanitized_name = sanitize_action_name(action_name)

        template 'example_action.rb', "app/reactive_actions/#{sanitized_name}.rb"
        say "✓ Created #{sanitized_name}.rb", :green unless options[:quiet]
      end
    end
  end
end
