# frozen_string_literal: true

require_relative 'lib/reactive_actions/version'

Gem::Specification.new do |spec|
  spec.name        = 'reactive-actions'
  spec.version     = ReactiveActions::VERSION
  spec.authors     = ['Istvan Meszaros']
  spec.email       = ['meszarosistvan97@gmail.com']
  spec.homepage    = 'https://github.com/IstvanMs/reactive-actions'
  spec.summary     = 'ReactiveActions for Rails applications'
  spec.description = 'A modern framework for creating HTTP API endpoints that execute server-side actions in Rails applications with automatic JavaScript client integration.'
  spec.license     = 'MIT'

  spec.metadata['homepage_uri'] = spec.homepage
  spec.metadata['source_code_uri'] = spec.homepage
  spec.metadata['changelog_uri'] = "#{spec.homepage}/blob/main/CHANGELOG.md"

  spec.require_paths = ['lib']
  spec.files = Dir.glob('{app,config,db,lib}/**/*') + %w[MIT-LICENSE Rakefile README.md]

  spec.required_ruby_version = '>= 3.0.0'

  spec.add_dependency 'rails', '>= 7.0', '< 9.0'

  spec.post_install_message = <<-MESSAGE
    Thank you for installing ReactiveActions!

    To complete the setup, please run:
      rails generate reactive_actions:install

    This will add the necessary routes to your application.
  MESSAGE
  spec.metadata['rubygems_mfa_required'] = 'true'
end
