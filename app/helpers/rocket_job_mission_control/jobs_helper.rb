module RocketJobMissionControl
  module JobsHelper
    def job_state_icon(state)
      case state
      when :queued, :paused
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
      when :queued, :aborted, :paused
        "warning"
      when :running
        "primary"
      when :completed
        "success"
      when :failed
        "danger"
      else
        ""
      end
    end

    def job_duration(job)
      started_at = job.started_at
      time_to    = job.completed_at || Time.now
      distance_of_time_in_words(started_at, time_to, highest_measure_only: true, include_seconds: true)
    end

    def pretty_print_arguments(arguments)
      return arguments unless arguments.kind_of?(Array) || arguments.kind_of?(Hash)
      json_string_options = {space: ' ', indent: '  ', array_nl: '<br />', object_nl: '<br />'}
      JSON.generate(arguments, json_string_options).html_safe
    end

    def job_title(job)
      perform_method = job.perform_method == :perform ? '' : "##{job.perform_method}"
      "#{job.priority} - #{job.klass}#{perform_method}"
    end
  end
end
