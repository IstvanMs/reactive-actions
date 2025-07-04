Rails.application.routes.draw do
  root 'test#index'
  get 'test', to: 'test#index'
  get 'test/api', to: 'test#api_test'
  get 'test/dom', to: 'test#dom_test'
  get 'test/security', to: 'test#security_test'
  get 'test/manual', to: 'test#manual_test'
  get 'test/rate_limit', to: 'test#rate_limit_test'
  mount ReactiveActions::Engine, at: '/reactive_actions'
end