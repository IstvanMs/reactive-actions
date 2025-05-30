# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'ReactiveActions Integration', type: :request do
  describe '/reactive_actions without correct path' do
    it 'returns 404 when accessing without /execute' do
      get '/reactive_actions'
      expect(response).to have_http_status(:not_found)
    end

    it 'returns 404 when accessing a non existing path' do
      get '/reactive_actions/non_existing_path'
      expect(response).to have_http_status(:not_found)
    end
  end

  describe '/reactive_actions/execute with different error scenario' do
    context 'when no action_name is provided' do
      it 'returns a missing parameter error' do
        get '/reactive_actions/execute'
        expect(response).to have_http_status(:bad_request)

        json_response = response.parsed_body
        expect(json_response['success']).to be false
        expect(json_response['error']).to be_a(Hash)
        expect(json_response['error']['type']).to eq('MissingParameterError')
        expect(json_response['error']['code']).to eq('MISSING_PARAMETER')
      end
    end

    context 'when action does not exist' do
      it 'returns a not found error' do
        get '/reactive_actions/execute', params: { action_name: 'non_existent_action' }
        expect(response).to have_http_status(:not_found)

        json_response = response.parsed_body
        expect(json_response['success']).to be false
        expect(json_response['error']).to be_a(Hash)
        expect(json_response['error']['type']).to eq('ActionNotFoundError')
        expect(json_response['error']['code']).to eq('NOT_FOUND')
      end
    end
  end
end
