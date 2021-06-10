module RocketjobMissionControl
  class ServersDatatable < AbstractDatatable
    delegate :server_icon, :server_path, :stop_server_path, :resume_server_path, :pause_server_path, :server_card_class, to: :@view

    def initialize(view, query)
      query.display_columns = %w[name heartbeat.workers started_at heartbeat.updated_at]
      query.search_columns  = [:name]
      super(view, query)
    end

    private

    def map(server)
      {
        "0"           => name_with_icon(server),
        "1"           => h(threads(server)),
        "2"           => h(started_ago(server)),
        "3"           => h(time_since_heartbeat(server)),
        "4"           => action_links_html(server),
        "DT_RowClass" => "card callout #{server_card_class(server)}"
      }
    end

    def name_with_icon(server)
      <<-EOS
        <i class="#{server_icon(server)}" style="font-size: 75%" title="#{server.state}"></i>
        #{server.name}
      EOS
    end

    def threads(server)
      "#{server.try!(:heartbeat).try!(:workers).to_i}/#{server.max_workers}"
    end

    def started_ago(server)
      "#{RocketJob.seconds_as_duration(Time.now - (server.started_at || Time.now))} ago"
    end

    def time_since_heartbeat(server)
      "#{RocketJob.seconds_as_duration(Time.now - (server.try!(:heartbeat).try!(:updated_at) || Time.now))} ago"
    end

    def action_links_html(server)
      actions = '<div class="actions">'
      events  = valid_events(server)

      if events.include?(:resume) && view.can?(:resume, server)
        actions += (link_to "resume", resume_server_path(server), method: :patch, class: "btn btn-default", data: {confirm: "Resume this server?"}).to_s
      end

      if events.include?(:pause) && view.can?(:pause, server)
        actions += (link_to "pause", pause_server_path(server), method: :patch, class: "btn btn-default", data: {confirm: "Pause this server?"}).to_s
      end

      if events.include?(:stop) && view.can?(:stop, server)
        actions += (link_to "stop", stop_server_path(server), method: :patch, class: "btn btn-danger", data: {confirm: "Stop this server?"}).to_s
      end

      if server.stopping? && view.can?(:destroy, server)
        actions += "Server is stopping..."
        confirmation = ""
        unless server.zombie?
          confirmation << "Warning!\n\nDestroying this server will hard kill its active workers/jobs.\nKilled jobs will be requeued for processing on another worker.\n\n"
        end
        confirmation << "Are you sure you want to destroy #{server.name} ?"
        actions += (link_to "destroy", server_path(server), method: :delete, class: "btn btn-danger", data: {confirm: confirmation}).to_s
      end

      actions += "</div>"
    end

    def valid_events(server)
      server.aasm.events.collect(&:name)
    end
  end
end
