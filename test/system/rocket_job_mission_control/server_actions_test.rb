require_relative "../../test_helper"

module RocketJobMissionControl
  class ServerActionsTest < SystemTestCase
    describe "server action links" do
      before do
        RocketJob::Job.delete_all
        RocketJob::Server.delete_all
      end

      let :server do
        s = RocketJob::Server.new
        s.build_heartbeat(updated_at: Time.zone.now, workers: 0)
        s.started!
        s
      end

      # pause/resume/stop only publish a pub-sub message for a live Rocket Job
      # supervisor process to act on (see RocketJob::Subscribers::Server), so
      # the server's persisted state does not change synchronously within the
      # request. What is observable here is that the request was submitted
      # successfully, matching the flash message the controller sets.
      #
      # Action links are rendered client-side by DataTables (see
      # ServersDatatable#action_links_html), so the page needs to load and the
      # AJAX-populated row to appear before the link can be clicked.
      it "pauses a running server" do
        server
        visit running_servers_path

        accept_confirm { click_on "pause" }

        assert_text "Submitted pause request to Rocket Job server: #{server.name}."
      end

      it "resumes a paused server" do
        server.pause!
        visit paused_servers_path

        accept_confirm { click_on "resume" }

        assert_text "Submitted resume request to Rocket Job server: #{server.name}."
      end

      it "stops a running server" do
        server
        visit running_servers_path

        accept_confirm { click_on "stop" }

        assert_text "Submitted stop request to Rocket Job server: #{server.name}."
      end

      it "destroys a stopping server" do
        server_id = server.id
        server.stop!
        visit stopping_servers_path

        accept_confirm { click_on "destroy" }

        assert_not RocketJob::Server.where(id: server_id).exists?
      end
    end
  end
end
