# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe ReactiveActionsController, type: :controller do
    routes { ReactiveActions::Engine.routes }

    let(:action_name) { 'test' }
    let(:sub_folder_action_name) { 'sub_folder' }
    let(:action_params) { { name: 'John Doe' } }

    describe 'requests with incorrect path' do
      it 'does not route to execute action' do
        expect(get: '/').not_to route_to(
          controller: 'reactive_actions/reactive_actions',
          action: 'execute'
        )
      end

      it 'routes correctly to execute action' do
        expect(get: '/execute').to route_to(
          controller: 'reactive_actions/reactive_actions',
          action: 'execute'
        )
      end
    end

    describe '#execute with different error scenarios' do
      context 'when no action_name is provided' do
        it 'returns a missing parameter error' do
          post :execute, params: { action_params: {} }

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
          post :execute, params: { action_name: 'non_existent_action' }
          expect(response).to have_http_status(:not_found)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('ActionNotFoundError')
          expect(json_response['error']['code']).to eq('NOT_FOUND')
        end
      end

      context 'when an error occurs in the action' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ActionExecutionError, 'Test error')

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('ActionExecutionError')
          expect(json_response['error']['code']).to eq('EXECUTION_ERROR')
        end
      end

      context 'when ReactiveActions::ActionNotFoundError triggered' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ReactiveActions::ActionNotFoundError)

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:not_found)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('ActionNotFoundError')
          expect(json_response['error']['code']).to eq('NOT_FOUND')
        end
      end

      context 'when ReactiveActions::MissingParameterError triggered' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ReactiveActions::MissingParameterError)

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:bad_request)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('MissingParameterError')
          expect(json_response['error']['code']).to eq('MISSING_PARAMETER')
        end
      end

      context 'when ReactiveActions::InvalidParametersError triggered' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ReactiveActions::InvalidParametersError)

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:bad_request)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('InvalidParametersError')
          expect(json_response['error']['code']).to eq('INVALID_PARAMETERS')
        end
      end

      context 'when ReactiveActions::UnauthorizedError triggered' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ReactiveActions::UnauthorizedError)

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:forbidden)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('UnauthorizedError')
          expect(json_response['error']['code']).to eq('UNAUTHORIZED')
        end
      end

      context 'when ReactiveActions::ActionExecutionError triggered' do
        it 'returns an error response' do
          mock_action = instance_double(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(mock_action)
          allow(mock_action).to receive(:run).and_raise(ReactiveActions::ActionExecutionError)

          post :execute, params: { action_name: action_name }
          expect(response).to have_http_status(:unprocessable_entity)

          json_response = response.parsed_body
          expect(json_response['success']).to be false
          expect(json_response['error']).to be_a(Hash)
          expect(json_response['error']['type']).to eq('ActionExecutionError')
          expect(json_response['error']['code']).to eq('EXECUTION_ERROR')
        end
      end
    end
  end
end
