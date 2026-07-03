module RocketJobMissionControl
  class ActiveWorkersDatatable < AbstractDatatable
    delegate :job_path, :state_icon, to: :@view

    private

    def extract_query_params
      @query.order_by = nil
    end

    def map(active_worker)
      {
        "0"           => worker_name_with_icon(active_worker, active_worker.job),
        "1"           => server_status(active_worker),
        "2"           => job_name_with_link(active_worker.job.class.name, active_worker.job.id),
        "3"           => h(active_worker.job.description&.truncate(50)),
        "4"           => h("#{active_worker.duration} ago"),
        "DT_RowClass" => "card callout callout-running"
      }
    end

    def worker_name_with_icon(active_worker, job)
      state = active_worker.zombie? ? :zombie : job.state
      <<-EOS
        <i class="#{state_icon(state)}" style="font-size: 75%" title="#{state}"></i>
        #{active_worker.name}
      EOS
    end

    # The server the worker is running on, along with its current status.
    # A missing server means the worker has been orphaned (zombie).
    def server_status(active_worker)
      if active_worker.zombie?
        state = :zombie
        label = "zombie"
      else
        state = active_worker.server.state
        label = h(state)
      end
      <<-EOS
        <i class="#{state_icon(state)}" style="font-size: 75%" title="#{state}"></i>
        #{h(active_worker.server_name)} (#{label})
      EOS
    end

    def job_name_with_link(job_class_name, job_id)
      <<-EOS
        <a href="#{job_path(job_id)}">
          #{job_class_name}
        </a>
      EOS
    end
  end
end
