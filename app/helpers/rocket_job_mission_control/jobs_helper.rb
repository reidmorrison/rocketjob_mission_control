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

    def job_duration(job)
      started_at = job.status[:started_at]
      time_to    = if job.completed?
                     job.status[:completed_at]
                   elsif job.aborted?
                     job.status[:aborted_at]
                   else
                     Time.now
                   end
      distance_of_time_in_words(started_at, time_to, highest_measure_only: true, include_seconds: true)
    end

    def pretty_print_arguments(arguments)
      return arguments unless arguments.kind_of?(Array) || arguments.kind_of?(Hash)
      json_string_options = {space: ' ', indent: '  ', array_nl: '<br />', object_nl: '<br />'}
      JSON.generate(arguments, json_string_options).html_safe
    end
  end
end
