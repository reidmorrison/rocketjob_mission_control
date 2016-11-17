module RocketJobMissionControl
  class ServersDatatable
    delegate :params,
      :link_to,
      :server_icon,
      :server_path,
      :stop_server_path,
      :resume_server_path,
      :pause_server_path,
      :server_card_class,
      :render, to: :@view

    delegate :h, to: 'ERB::Util'

    def initialize(view, servers)
      @view               = view
      @unfiltered_servers = servers
    end

    def as_json(options = {})
      {
        :draw            => params[:draw].to_i,
        :recordsTotal    => get_raw_records.count,
        :recordsFiltered => filter_records(get_raw_records).count,
        :data            => data
      }
    end

    private

    def data
      servers.collect do |server|
        {
          '0'           => name_with_icon(server),
          '1'           => h(threads(server)),
          '2'           => h(started_ago(server)),
          '3'           => h(time_since_heartbeat(server)),
          '4'           => action_links_html(server),
          'DT_RowClass' => "card callout #{server_card_class(server)}"
        }
      end
    end

    def get_raw_records
      @unfiltered_servers
    end

    def servers
      @servers ||= fetch_servers.to_a
    end

    def fetch_servers
      records = get_raw_records
      records = sort_records(records) if params[:order].present?
      records = filter_records(records) if params[:search].present?
      records = paginate_records(records) unless params[:length].present? && params[:length] == '-1'
      records
    end

    def page
      (params[:start].to_i / per_page) + 1
    end

    def per_page
      params.fetch(:length, 10).to_i
    end

    def sort_records(records)
      sort_by = {}
      params[:order].keys.each do |key|
        sort_by[sort_column(params[:order][key][:column])] = params[:order][key][:dir]
      end
      records.sort(sort_by)
    end

    def sort_column(index)
      columns = %w[name max_workers started_at heartbeat.updated_at]
      columns[index.to_i]
    end

    def filter_records(records)
      return records unless (params[:search].present? && params[:search][:value].present?)
      conditions = params[:search][:value]
      records    = RocketJobMissionControl::Servers::Search.new(conditions, records).execute if conditions
      records
    end

    def paginate_records(records)
      Kaminari.paginate_array(records.to_a).page(page).per(per_page)
    end

    def name_with_icon(server)
      <<-EOS
        <i class="fa #{server_icon(server)}" style="font-size: 75%" title="#{server.state}"></i>
        #{server.name}
      EOS
    end

    def threads(server)
      "#{server.heartbeat.workers.to_i}/#{server.max_workers}"
    end

    def started_ago(server)
      "#{RocketJob.seconds_as_duration(Time.now - server.started_at)} ago"
    end

    def time_since_heartbeat(server)
      "#{RocketJob.seconds_as_duration(Time.now - server.heartbeat.updated_at)} ago"
    end

    def action_links_html(server)
      actions = '<div class="actions">'
      if server.stopping?
        actions += "Server is stopping..."
        confirmation = ''
        unless server.zombie?
          confirmation << "Warning!\n\nDestroying this server will hard kill its active workers/jobs.\nKilled jobs will be requeued for processing on another worker.\n\n"
        end
        confirmation << "Are you sure you want to destroy #{server.name} ?"
        actions += "#{ link_to "destroy", server_path(server), method: :delete, class: 'btn btn-danger', data: {confirm: confirmation}  }"
      else
        if server.paused?
          actions += "#{ link_to "resume", resume_server_path(server), method: :patch, class: 'btn btn-default', data: {confirm: "Resume this server?"}  }"
        else
          actions += "#{ link_to "pause", pause_server_path(server), method: :patch, class: 'btn btn-default', data: {confirm: "Pause this server?"} }"
        end
        actions += "#{ link_to "stop", stop_server_path(server), method: :patch, class: 'btn btn-danger', data: {confirm: "Stop this server?"} }"
      end
      actions += '</div>'
    end
  end
end
