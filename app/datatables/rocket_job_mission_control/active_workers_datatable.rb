module RocketJobMissionControl
  class ActiveWorkersDatatable < AbstractDatatable
    delegate :job_path, :state_icon, to: :@view

    def initialize(view, query)
      super(view, query)
    end

    private

    def extract_query_params
      @query.order_by = nil
    end

    def map(active_worker)
      {
        '0'           => worker_name_with_icon(active_worker, active_worker.job),
        '1'           => job_name_with_link(active_worker.job.class.name, active_worker.job.id),
        '2'           => h(active_worker.job.description.try!(:truncate, 50)),
        '3'           => h("#{active_worker.duration} ago"),
        'DT_RowClass' => 'card callout callout-running'
      }
    end

    def worker_name_with_icon(active_worker, job)
      state = active_worker.zombie? ? :zombie : job.state
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
