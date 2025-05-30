# frozen_string_literal: true

ReactiveActions::Engine.routes.draw do
  match '/execute', to: 'reactive_actions#execute', via: %i[get post put patch delete]
end
