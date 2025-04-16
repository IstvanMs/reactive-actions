# frozen_string_literal: true

ReactiveActions::Engine.routes.draw do
  # Match all HTTP verbs to the execute action
  match '/execute', to: 'reactive_actions#execute', via: [:get, :post, :put, :patch, :delete]
  
  # Default route also goes to execute
  root to: 'reactive_actions#execute'
end