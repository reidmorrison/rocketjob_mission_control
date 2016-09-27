module RocketJobMissionControl
  class ActiveProcessesDatatable
    delegate :params, :link_to, :job_path, :state_icon, to: :@view
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
      processes.map do |h|
        {
          '0' => worker_name_with_icon(h[:worker_name]),
          '1' => job_name_with_link(h[:klass], h[:id]),
          '2' => h(h[:description].try!(:truncate, 50)),
          '3' => h(duration(h[:started_at])),
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

    def worker_name_with_icon(worker_name)
      <<-EOS
        <i class="fa #{state_icon(:running)}" style="font-size: 75%" title="running"></i>
        #{worker_name}
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
      "#{RocketJob.seconds_as_duration(Time.now - started_at)}" if started_at
    end
  end
end
