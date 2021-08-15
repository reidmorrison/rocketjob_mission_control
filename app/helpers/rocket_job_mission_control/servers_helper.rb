module RocketJobMissionControl
  module ServersHelper
    def server_counts_by_state(state)
      @server_counts.fetch(state.downcase.to_sym, 0)
    end

    def server_icon(server)
      state =
        if server.zombie?
          "zombie"
        else
          server.state
        end
      state_icon(state)
    end

    def server_card_class(server)
      if server.zombie?
        "callout-zombie"
      else
        map = {
          running:  "callout-success",
          paused:   "callout-warning",
          stopping: "callout-alert"
        }
        map[server.state] || "callout-info"
      end
    end
    
    def rocket_job_mission_control
      @@rocket_job_mission_control_engine_url_helpers ||= RocketJobMissionControl::Engine.routes.url_helpers
    end
  end
end
