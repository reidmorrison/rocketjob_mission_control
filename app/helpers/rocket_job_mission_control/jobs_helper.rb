module RocketJobMissionControl
  module JobsHelper
    # The fields that RJMC already displays, all other will be rendered under the custom section.
    DISPLAYED_FIELDS = %w[
      _id _type
      completed_at created_at cron_schedule
      description destroy_on_complete download_encryption
      exception expires_at
      failed_at_list failure_count
      input_categories
      log_level
      output_categories output_path
      percent_complete priority
      record_count retry_limit run_at
      started_at state statistics sub_state
      throttle_group throttle_running_workers
      upload_file_name
      worker_name
    ]

    def job_icon(job)
      state = job_state(job)
      state_icon(state)
    end

    def job_state(job)
      if job.scheduled?
        :scheduled
      elsif job.sleeping?
        :sleeping
      else
        job.state
      end
    end

    def job_state_name(job)
      job_state(@job).to_s.camelcase
    end

    def job_time(time)
      return "" unless time
      time.in_time_zone(Time.zone)
    end

    def job_state_time(job)
      return job_time(job.run_at) if job.scheduled?

      job_time(job.completed_at || job.started_at || job.created_at )
      # job_time(job.running? ? job.started_at : job.completed_at)
    end

    def job_estimated_time_left(job)
      if job.record_count && job.running? && job.record_count.positive?
        percent = job.percent_complete
        if percent >= 5
          secs = job.seconds.to_f
          RocketJob.seconds_as_duration((((secs / percent) * 100) - secs))
        end
      end
    end

    def job_records_per_hour(job)
      return unless job.completed?

      secs = job.seconds.to_f
      ((job.record_count.to_f / secs) * 60 * 60).round if job.record_count&.positive? && (secs > 0.0)
    end

    def job_custom_fields(job)
      attrs = job.attributes.dup
      DISPLAYED_FIELDS.each { |key| attrs.delete(key) }
      # Convert time zones for any custom time fields
      attrs.keys { |key| attrs[key] = attrs[key].in_time_zone(Time.zone) if attrs[key].is_a?(Time) }
      attrs
    end

    def job_states
      @job_states ||= RocketJob::Job.aasm.states.map { |state| state.name.to_s }
    end

    def job_states_with_scheduled
      @job_states_with_scheduled ||= ["scheduled"] + job_states
    end

    def job_counts_by_state(state)
      @job_counts ||= begin
                        counts          = RocketJob::Job.counts_by_state
                        counts[:queued] = counts[:queued_now] || 0
                        counts
                      end
      @job_counts.fetch(state.downcase.to_sym, 0)
    end

    def job_action_link(action, path, http_method = :get)
      link_to(
        action,
        path,
        method: http_method,
        title:  "#{action} job",
        class:  "btn btn-default",
        data:   {confirm: t(:confirm, scope: %i[job action], action: action)}
      )
    end

    def job_action_links_for_show(action, path, http_method = :get)
      link_to(
        action,
        path,
        method: http_method,
        title:  "#{action} job",
        class:  "btn btn-primary",
        data:   {confirm: t(:confirm, scope: %i[job action], action: action)}
      )
    end

    def job_selected_class(job, selected_job)
      if selected_job.present? && job.id == selected_job.id
        "selected"
      else
        ""
      end
    end
  end
end
