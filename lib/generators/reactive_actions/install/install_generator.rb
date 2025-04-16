# frozen_string_literal: true

module ReactiveActions
  module Generators
    class InstallGenerator < Rails::Generators::Base
      source_root File.expand_path('templates', __dir__)
      
      def add_routes
        route "mount ReactiveActions::Engine, at: '/reactive_actions'"
      end
      
      def show_readme
        readme "README" if behavior == :invoke
      end
    end
  end
end