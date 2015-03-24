module RocketJobMissionControl
  module JobsHelper
    def job_state_icon(state)
      case state
      when :queued
        'fa-bed warning'
      when :running
        'fa-cog fa-spin primary'
      when :completed
        'fa-check-circle-o success'
      when :aborted
        'fa-times-circle-o warning'
      else
        'fa-times-circle-o danger'
      end
    end

    def job_class(job)
      case job.state
      when :queued
        "warning"
      when :running
        "primary"
      when :completed
        "success"
      when :aborted
        "warning"
      when :failed
        "danger"
      else
        ""
      end
    end
  end
end
