# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe ReactiveActionsController, type: :controller do
    routes { ReactiveActions::Engine.routes }
    
    let(:action_name) { "test_action" }
    let(:action_params) { { "key" => "value" } }
    
    describe "#execute with different HTTP methods" do
      
      [:get, :post, :put, :patch, :delete].each do |http_method|
        describe "#{http_method.upcase} #execute" do
          it "returns a successful response" do
            send(http_method, :execute, params: { action_name: action_name, action_params: action_params })
            expect(response).to be_successful
          end
          
          it "returns the correct response format" do
            send(http_method, :execute, params: { action_name: action_name, action_params: action_params })
            json_response = JSON.parse(response.body)
            
            expect(json_response["success"]).to be true
            expect(json_response["http_method"]).to include(http_method.to_s.upcase)
            expect(json_response["action"]).to eq(action_name)
            expect(json_response["message"]).to include(action_name)
            expect(json_response["data"]).to eq(action_params.as_json)
          end
        end
      end
      
      context "when an error occurs" do
        before do
          allow_any_instance_of(ReactiveActionsController).to receive(:execute).and_raise("Test error")
        end
        
        it "returns an error response" do
          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:unprocessable_entity)
          
          json_response = JSON.parse(response.body)
          expect(json_response["success"]).to be false
          expect(json_response["error"]).to be_present
        end
      end
    end
    
    describe "root route" do
      it "routes to execute action" do
        expect(get: "/").to route_to(
          controller: "reactive_actions/reactive_actions",
          action: "execute"
        )
      end
    end
  end
end