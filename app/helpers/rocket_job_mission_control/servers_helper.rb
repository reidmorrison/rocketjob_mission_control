module RocketJobMissionControl
  module ServersHelper

    def server_card_class(server)
      map = {
        running:  'callout-success-top',
        paused:   'callout-warning-top',
        stopping: 'callout-alert-top',
      }
      map[server.state] || 'callout-info-top'
    end

  end
end
