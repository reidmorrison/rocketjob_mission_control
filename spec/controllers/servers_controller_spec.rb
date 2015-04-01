require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe ServersController do
    routes { Engine.routes }

    describe "PATCH #stop" do
      describe "with a valid server id" do
        let(:server) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Server).to receive(:find).and_return(server)
          patch :stop, id: server.id
        end

        it "redirects to servers" do
          expect(response).to redirect_to(servers_path)
        end

        it "displays a flash message" do
          expect(flash[:notice]).to eq(I18n.t(:success, scope: [:server, :stop]))
        end

        it "stops the server" do
          expect(server).to have_received(:stop!)
        end
      end

      describe "when the server fails to stop" do
        before do
          server = spy(stop!: false)
          allow(RocketJob::Server).to receive(:find).and_return(server)
          patch :stop, id: server.id
        end

        it "redirects to servers" do
          expect(response).to redirect_to(servers_path)
        end

        it "displays a flash message" do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:server, :stop]))
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

      describe "when the server fails to stop" do
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
