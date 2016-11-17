module RocketJobMissionControl
  class ActiveWorkersDatatable
    delegate :params, :link_to, :job_path, :state_icon, to: :@view
    delegate :h, to: 'ERB::Util'

    def initialize(view, active_workers)
      @view                      = view
      @unfiltered_active_workers = active_workers
    end

    def as_json(options = {})
      {
        draw:            params[:draw].to_i,
        recordsTotal:    get_raw_records.count,
        recordsFiltered: get_raw_records.count,
        data:            data
      }
    end

    private

    def data
      active_workers.collect do |active_worker|
        {
          '0'           => worker_name_with_icon(active_worker),
          '1'           => job_name_with_link(active_worker.job.class.name, active_worker.job.id),
          '2'           => h(active_worker.job.description.try!(:truncate, 50)),
          '3'           => h("#{active_worker.duration} ago"),
          'DT_RowClass' => 'card callout callout-running'
        }
      end
    end

    def get_raw_records
      @unfiltered_active_workers
    end

    def active_workers
      @active_workers ||= fetch_active_workers
    end

    def fetch_active_workers
      records = get_raw_records
      records = paginate_records(records) unless params[:length].present? && params[:length] == '-1'
      records
    end

    def page
      (params[:start].to_i / per_page) + 1
    end

    def per_page
      params.fetch(:length, 10).to_i
    end

    def paginate_records(records)
      Kaminari.paginate_array(records).page(page).per(per_page)
    end

    def worker_name_with_icon(active_worker)
      state = active_worker.zombie? ? :zombie : :running
      <<-EOS
        <i class="fa #{state_icon(state)}" style="font-size: 75%" title="#{state}"></i>
        #{active_worker.name}
      EOS
    end

    def job_name_with_link(job_class_name, job_id)
      <<-EOS
        <a href="#{job_path(job_id)}">
          #{job_class_name}
        </a>
      EOS
    end

    def duration(started_at)
      "#{RocketJob.seconds_as_duration(Time.now - started_at)} ago" if started_at
    end
  end
end
