require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe ServersController do
    routes { Engine.routes }

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

        it "destroys the server" do
          expect(server).to have_received(:destroy)
        end
      end
    end
  end
end
