# frozen_string_literal: true

require 'rails_helper'

module ReactiveActions
  RSpec.describe ReactiveActionsController, type: :controller do
    routes { ReactiveActions::Engine.routes }

    let(:action_name) { 'test' }
    let(:sub_folder_action_name) { 'sub_folder' }
    let(:action_params) { { name: 'John Doe' } }
    let(:test_action_instance) { instance_double(ReactiveActions::TestAction) }
    let(:sub_folder_action_instance) { instance_double(ReactiveActions::SubFolderAction) }

    describe '#execute with different HTTP methods' do
      %i[get post put patch delete].each do |http_method|
        describe "#{http_method.upcase} #execute" do
          it 'returns a successful response' do
            send(http_method, :execute, params: { action_name: action_name, action_params: action_params })
            expect(response).to be_successful
          end

          it 'executes the requested action' do
            allow(ReactiveActions::TestAction).to receive(:new).and_return(test_action_instance)
            allow(test_action_instance).to receive(:run) do
              controller.render json: { success: true, test: true }
            end

            send(http_method, :execute, params: { action_name: action_name, action_params: action_params })

            expect(ReactiveActions::TestAction).to have_received(:new).with(controller, name: 'John Doe')
            expect(test_action_instance).to have_received(:run)
          end

          it 'executes the requested action from sub folder' do
            allow(ReactiveActions::SubFolderAction).to receive(:new).and_return(sub_folder_action_instance)
            allow(sub_folder_action_instance).to receive(:run) do
              controller.render json: { success: true, from_sub_folder: true }
            end

            send(http_method, :execute, params: { action_name: sub_folder_action_name })

            expect(ReactiveActions::SubFolderAction).to have_received(:new).with(controller)
            expect(sub_folder_action_instance).to have_received(:run)
          end
        end
      end

      context 'when action params are properly processed' do
        it 'correctly passes params to the action' do
          action_spy = instance_spy(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(action_spy)
          allow(action_spy).to receive(:run) do
            controller.render json: { success: true }
          end

          post :execute, params: { action_name: action_name, action_params: action_params }

          expect(ReactiveActions::TestAction).to have_received(:new).with(controller, name: 'John Doe')
          expect(action_spy).to have_received(:run)
          expect(response).to be_successful
        end
      end

      context 'with POST specific behavior' do
        it 'accepts complex nested parameters' do
          complex_params = { 'user' => { 'name' => 'John', 'profile' => { 'age' => 30 } } }
          action_spy = instance_spy(ReactiveActions::TestAction)
          allow(ReactiveActions::TestAction).to receive(:new).and_return(action_spy)
          allow(action_spy).to receive(:run) do
            controller.render json: { success: true }
          end

          post :execute, params: { action_name: action_name, action_params: complex_params }

          expect(ReactiveActions::TestAction).to have_received(:new).with(
            controller,
            user: { 'name' => 'John', 'profile' => { 'age' => '30' } }
          )
          expect(response).to be_successful
        end
      end
    end
  end
end
