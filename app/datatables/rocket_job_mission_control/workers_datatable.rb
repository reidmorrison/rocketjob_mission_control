module RocketJobMissionControl
  class WorkersDatatable
    delegate :params,
             :link_to,
             :worker_icon,
             :worker_path,
             :stop_worker_path,
             :resume_worker_path,
             :pause_worker_path,
             :worker_card_class,
             :render, to: :@view

    delegate :h, to: 'ERB::Util'

    def initialize(view, workers)
      @view = view
      @unfiltered_workers = workers
    end

    def as_json(options = {})
      {
        :draw => params[:draw].to_i,
        :recordsTotal =>  get_raw_records.count,
        :recordsFiltered => filter_records(get_raw_records).count,
        :data => data
      }
    end

    private

    def data
      workers.map do |worker|
        {
          '0' => name_with_icon(worker),
          '1' => h(threads(worker)),
          '2' => h(started_ago(worker)),
          '3' => h(time_since_heartbeat(worker)),
          '4' => action_links_html(worker),
          'DT_RowClass' => "card callout #{worker_card_class(worker)}"
        }
      end
    end

    def get_raw_records
      @unfiltered_workers
    end

    def workers
      @workers ||= fetch_workers
    end

    def fetch_workers
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
      columns = %w[name max_threads started_at heartbeat.updated_at]
      columns[index.to_i]
    end

    def filter_records(records)
      return records unless (params[:search].present? && params[:search][:value].present?)
      conditions = params[:search][:value]
      records = RocketJobMissionControl::Workers::Search.new(conditions, records).execute if conditions
      records
    end

    def paginate_records(records)
      Kaminari.paginate_array(records).page(page).per(per_page)
    end

    def name_with_icon(worker)
      <<-EOS
        <i class="fa #{worker_icon(worker)}" style="font-size: 75%" title="#{worker.state}"></i>
        #{worker.name}
      EOS
    end

    def threads(worker)
      "#{worker.heartbeat.current_threads.to_i}/#{worker.max_threads}"
    end

    def started_ago(worker)
      "#{RocketJob.seconds_as_duration(Time.now - worker.started_at)} ago"
    end

    def time_since_heartbeat(worker)
      "#{RocketJob.seconds_as_duration(Time.now - worker.heartbeat.updated_at)} ago"
    end

    def action_links_html(worker)
      actions = '<div class="actions">'
      if worker.stopping?
        actions += "Worker is stopping..."
        actions += "#{ link_to "destroy", worker_path(worker), method: :delete, class: 'btn btn-danger', data: { confirm: "Destroy this worker?"}  }"
      else
        if worker.paused?
          actions += "#{ link_to "resume", resume_worker_path(worker), method: :patch, class: 'btn btn-default', data: { confirm: "Resume this worker?"}  }"
        else
          actions += "#{ link_to "pause", pause_worker_path(worker), method: :patch, class: 'btn btn-default', data: { confirm: "Pause this worker?"} }"
        end
        actions += "#{ link_to "stop", stop_worker_path(worker), method: :patch, class: 'btn btn-danger', data: { confirm: "Stop this worker?"} }"
      end
      actions += '</div>'
    end
  end
end
