module RocketJobMissionControl
  module JobsHelper
    STATE_ICON_MAP = {
      queued:    'fa-bed warning',
      paused:    'fa-pause warning',
      running:   'fa-cog fa-spin primary',
      completed: 'fa-check success',
      aborted:   'fa-times warning',
    }

    STATE_CLASS_MAP = {
      queued:    'warning',
      paused:    'warning',
      running:   'primary',
      completed: 'success',
      aborted:   'danger',
      failed:    'danger',
    }

    def job_state_icon(state)
      STATE_ICON_MAP[state.to_sym] || 'fa-times danger'
    end

    def job_class(job)
      STATE_CLASS_MAP[job.state.to_sym] || ""
    end

    def job_duration(job)
      started_at = job.started_at   || Time.now
      time_to    = job.completed_at || Time.now
      distance_of_time_in_words(started_at, time_to, highest_measure_only: true, include_seconds: true)
    end

    def pretty_print_array_or_hash(arguments)
      return arguments unless arguments.kind_of?(Array) || arguments.kind_of?(Hash)
      json_string_options = {space: ' ', indent: '  ', array_nl: '<br />', object_nl: '<br />'}
      JSON.generate(arguments, json_string_options).html_safe
    end

    def job_card_class(job)
      map = {
        running:   'callout-info',
        completed: 'callout-success',
        failed:    'callout-alert',
        aborted:   'callout-warning',
      }
      "card callout " << map[job.state.to_sym].to_s
    end

    def job_selected_class(job, selected_job = nil)
      if selected_job.present? && job.id == selected_job.id
        ' text-info'
      else
        ' text-muted'
      end
    end

    def job_title(job)
      perform_method = job.perform_method == :perform ? '' : "##{job.perform_method}"
      "#{job.class.name}#{perform_method}"
    end
  end
end
