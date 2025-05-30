# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ReactiveActions Integration', type: :request do
  let(:action_name) { 'test_action' }
  let(:action_params) { { key: 'value' } }

  describe '/reactive_actions/execute with different HTTP methods' do
    it 'supports GET requests' do
      get '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
      expect(response).to have_http_status(200)
    end

    it 'supports POST requests' do
      post '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
      expect(response).to have_http_status(200)
    end

    it 'supports PUT requests' do
      put '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
      expect(response).to have_http_status(200)
    end

    it 'supports PATCH requests' do
      patch '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
      expect(response).to have_http_status(200)
    end

    it 'supports DELETE requests' do
      delete '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
      expect(response).to have_http_status(200)
    end
  end

  describe '/reactive_actions/execute with parameter formats' do
    context 'when action params are properly processed' do
      it 'correctly passes params to the action' do
        post '/reactive_actions/execute', params: { action_name: action_name, action_params: action_params }
        expect(response).to be_successful
      end
    end

    context 'with POST specific behavior' do
      it 'accepts complex nested parameters' do
        complex_params = { 'user' => { 'name' => 'John', 'profile' => { 'age' => 30 } } }
        post '/reactive_actions/execute', params: { action_name: action_name, action_params: complex_params }
        expect(response).to be_successful
      end
    end
  end

  describe '/reactive_actions/execute with action from sub folder' do
    it 'correctly runs the action' do
      post '/reactive_actions/execute', params: { action_name: 'sub_folder' }
      expect(response).to be_successful

      json_response = response.parsed_body
      expect(json_response['from_sub_folder']).to be true
    end
  end
end
