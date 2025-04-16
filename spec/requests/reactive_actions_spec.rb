# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "ReactiveActions Integration", type: :request do
  let(:action_name) { "test_action" }
  let(:action_params) { { key: "value" } }
  
  describe "Root path" do
    it "routes to execute action" do
      get "/reactive_actions"
      expect(response).to have_http_status(200)
      
      json_response = JSON.parse(response.body)
      expect(json_response["success"]).to be true
    end
  end
  
  describe "/reactive_actions/execute with different HTTP methods" do
    http_methods = {
      get: -> { get "/reactive_actions/execute", params: { action_name: action_name, action_params: action_params } },
      post: -> { post "/reactive_actions/execute", params: { action_name: action_name, action_params: action_params } },
      put: -> { put "/reactive_actions/execute", params: { action_name: action_name, action_params: action_params } },
      patch: -> { patch "/reactive_actions/execute", params: { action_name: action_name, action_params: action_params } },
      delete: -> { delete "/reactive_actions/execute", params: { action_name: action_name, action_params: action_params } }
    }
    
    http_methods.each do |method_name, request_method|
      it "supports #{method_name.upcase} requests" do
        request_method.call
        expect(response).to have_http_status(200)
        
        json_response = JSON.parse(response.body)
        expect(json_response["success"]).to be true
        expect(json_response["http_method"]).to include(method_name.to_s.upcase)
        expect(json_response["action"]).to eq(action_name)
      end
    end
  end
end