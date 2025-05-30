Rails.application.routes.draw do
  mount ReactiveActions::Engine, at: '/reactive_actions'
end
