require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe ServersController do
    routes { Engine.routes }

    [:stop, :pause, :resume].each do |server_action|
      describe "PATCH ##{server_action}" do
        describe "with a valid server id" do
          let(:server) { spy(id: 42, to_param: 42) }

          before do
            allow(RocketJob::Server).to receive(:find).and_return(server)
            patch server_action, id: server.id
          end

          it "redirects to servers" do
            expect(response).to redirect_to(servers_path)
          end

          it "displays a flash message" do
            expect(flash[:notice]).to eq(I18n.t(:success, scope: [:server, server_action]))
          end

          it "#{server_action} the server" do
            expect(server).to have_received("#{server_action}!".to_sym)
          end
        end

        describe "when the server fails to #{server_action}" do
          before do
            server = spy("#{server_action}!".to_sym => false)
            allow(RocketJob::Server).to receive(:find).and_return(server)
            patch server_action, id: server.id
          end

          it "redirects to servers" do
            expect(response).to redirect_to(servers_path)
          end

          it "displays a flash message" do
            expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:server, server_action]))
          end
        end
      end
    end

    describe "PATCH #update_all" do
      RocketJobMissionControl::ServersController::VALID_STATES.each do |server_action, action_message|
        context "with '#{server_action}' as the server_action param" do
          before do
            allow(RocketJob::Server).to receive(server_action.to_sym)
            patch :update_all, server_action: server_action
          end

          it "redirects to servers" do
            expect(response).to redirect_to(servers_path)
          end
          it "displays a success message" do
            state_message = I18n.t(:success, scope: [:server, :update_all], server_action: action_message)
            expect(flash[:notice]).to eq(state_message)
          end
          it "does not display an error message" do
            expect(flash[:alert]).to be_nil
          end
        end
      end

      context "with an invalid server_action param" do
        before do
          patch :update_all, server_action: :bad_server_action
        end

        it "redirects to servers" do
          expect(response).to redirect_to(servers_path)
        end
        it "does not display a success message" do
          expect(flash[:notice]).to be_nil
        end
        it "displays an error message" do
          expect(flash[:alert]).to eq(I18n.t(:invalid, scope: [:server, :update_all]))
        end
      end
    end

    describe "DELETE #destroy" do
      describe "with a valid server id" do
        let(:server) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Server).to receive(:find).and_return(server)
          delete :destroy, id: server.id
        end

        it "redirects to servers" do
          expect(response).to redirect_to(servers_path)
        end

        it "displays a flash message" do
          expect(flash[:notice]).to eq(I18n.t(:success, scope: [:server, :destroy]))
        end

        it "destroys the server" do
          expect(server).to have_received(:destroy)
        end
      end

      describe "when the server fails to be destroyed" do
        before do
          server = spy(destroy: false)
          allow(RocketJob::Server).to receive(:find).and_return(server)
          delete :destroy, id: server.id
        end

        it "redirects to servers" do
          expect(response).to redirect_to(servers_path)
        end

        it "displays a flash message" do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:server, :destroy]))
        end
      end
    end
  end
end
