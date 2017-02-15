module RocketJobMissionControl
  module JobsHelper
    def job_icon(job)
      state =
        if job.scheduled?
          :scheduled
        else
          job.state
        end
      state_icon(state)
    end

    def job_counts_by_state(state)
      @job_counts.fetch(state.downcase.to_sym, 0)
    end

    def job_action_link(action, path, http_method=:get)
      link_to(
        action,
        path,
        method: http_method,
        title: "#{action} job",
        class:  'btn btn-default',
        data:   {confirm: t(:confirm, scope: [:job, :action], action: action)}
      )
    end

    def job_selected_class(job, selected_job)
      if selected_job.present? && job.id == selected_job.id
        'selected'
      else
        ''
      end
    end

  end
end
