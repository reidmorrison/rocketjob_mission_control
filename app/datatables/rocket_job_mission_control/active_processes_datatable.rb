module RocketJobMissionControl
  class ActiveProcessesDatatable
    delegate :params, :link_to, :job_path, :job_icon, to: :@view
    delegate :h, to: 'ERB::Util'

    def initialize(view, processes)
      @view = view
      @unfiltered_processes = processes
    end

    def as_json(options = {})
      {
        :draw => params[:draw].to_i,
        :recordsTotal =>  get_raw_records.count,
        :recordsFiltered => get_raw_records.count,
        :data => data
      }
    end

    private

    def data
      processes.map do |worker_name, job, started_at|
        {
          '0' => worker_name_with_icon(worker_name, job),
          '1' => job_name_with_link(job),
          '2' => h(job.description.try(:truncate, 50)),
          '3' => h(duration(started_at)),
          'DT_RowClass' => "card callout callout-running"
        }
      end
    end

    def get_raw_records
      @unfiltered_processes
    end

    def processes
      @processes ||= fetch_processes
    end

    def fetch_processes
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

    def worker_name_with_icon(worker_name, job)
      <<-EOS
        <i class="fa #{job_icon(job)}" style="font-size: 75%" title="#{job.state}"></i>
        #{worker_name}
      EOS
    end

    def job_name_with_link(job)
      <<-EOS
        <a href="#{job_path(job.id)}">
          #{job.class.name}
        </a>
      EOS
    end

    def duration(started_at)
      "#{RocketJob.seconds_as_duration(Time.now - started_at)} ago" if started_at
    end
  end
end
