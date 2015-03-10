module RocketJobMissionControl
  module JobsHelper
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
