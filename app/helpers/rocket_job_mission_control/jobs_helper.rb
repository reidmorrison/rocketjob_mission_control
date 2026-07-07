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
    ].freeze

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

    def job_state_name(_job)
      job_state(@job).to_s.camelcase
    end

    def job_time(time)
      return "" unless time

      time.in_time_zone(Time.zone)
    end

    def job_state_time(job)
      return job_time(job.run_at) if job.scheduled?

      job_time(job.completed_at || job.started_at || job.created_at)
      # job_time(job.running? ? job.started_at : job.completed_at)
    end

    def job_estimated_time_left(job)
      return unless job.record_count && job.running? && job.record_count.positive?

      percent = job.percent_complete
      return unless percent >= 5

      secs = job.seconds.to_f
      RocketJob.seconds_as_duration(((secs / percent) * 100) - secs)
    end

    def job_records_per_hour(job)
      return unless job.completed?

      secs = job.seconds.to_f
      ((job.record_count.to_f / secs) * 60 * 60).round if job.record_count&.positive? && (secs > 0.0)
    end

    # Ordered slice buckets for the batch job progress bar, each as
    # [label, css_state_class, count, percent_of_bar]. Left to right:
    # Queued, Active, Failed, Completed.
    #
    # Completed input slices are deleted as they finish, so the completed count
    # is derived from the total expected slices (see #job_total_slices) minus
    # those still queued, running, or failed. The percentages are normalized so
    # the four segments always fill the bar.
    #
    # The record count is set before a batch job starts running, so until it is
    # known the total is nil and every percentage is zero, leaving the bar empty.
    def job_slice_stats(job)
      queued    = job.input.queued.count
      active    = job.input.running.count
      failed    = job.input.failed.count
      total     = job_total_slices(job)
      completed = total ? [total - queued - active - failed, 0].max : 0

      buckets = [
        ["Queued",    "queued",    queued],
        ["Active",    "running",   active],
        ["Failed",    "failed",    failed],
        ["Completed", "completed", completed]
      ]
      sum = buckets.sum(&:last)
      buckets.map do |label, css_class, count|
        percent = total && sum.positive? ? ((count * 100.0) / sum).round(2) : 0
        [label, css_class, count, percent]
      end
    end

    # Total number of input slices originally created for a batch job, or nil
    # when the record count is not yet known (for example while records are
    # still being uploaded).
    def job_total_slices(job)
      return nil unless job.record_count&.positive?

      (job.record_count.to_f / job.input_category.slice_size).ceil
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
        class:  "btn btn-secondary",
        data:   {confirm: t(:confirm, scope: %i[job action], action: action)}
      )
    end

    def job_action_links_for_show(action, path, http_method = :get)
      link_to(
        action,
        path,
        method: http_method,
        title:  "#{action} job",
        class:  "btn btn-secondary btn-group",
        role:   "group",
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

    def job_find_category(categories, category_name = :main)
      return unless categories

      categories.each { |category| return category if category_name == (category["name"] || :main).to_sym }
      nil
    end

    # Paths that live inside a gem or Ruby's standard library. Frames rooted at
    # any of these are treated as noise and hidden from the abbreviated
    # backtrace. This mirrors SemanticLogger::Utils.strip_path? without depending
    # on that internal method, so it keeps working regardless of the installed
    # Semantic Logger version.
    def backtrace_strip_paths
      @backtrace_strip_paths ||= (Gem.path | [Gem.default_dir, RbConfig::CONFIG["rubylibdir"]]).compact
    end

    # Returns [true|false] whether the backtrace line originates from a gem or
    # from Ruby itself, and so should be omitted from the abbreviated backtrace.
    def backtrace_noise?(line)
      backtrace_strip_paths.any? { |path| line.to_s.start_with?(path) }
    end

    # Reversible, ASCII-safe form of a failed record for an edit textarea.
    # See RecordEscaper; unescape it with RecordEscaper.unescape on save.
    def escape_record(value)
      RecordEscaper.escape(value)
    end

    # Read-only HTML for a failed record, with each unprintable/invalid byte
    # rendered as a highlighted `\xHH` token. Each highlight carries a hover
    # tooltip naming the byte, so an operator can see (in context) exactly which
    # byte broke the record and what it is.
    def highlight_record(value)
      safe_join(
        RecordEscaper.segments(value).map do |type, text|
          next text if type == :text

          content_tag(:span, text, class: "record-escape", title: record_escape_title(text))
        end
      )
    end

    # Human-readable names for the control bytes that can appear as escapes, used
    # for the hover tooltip on a highlighted record byte. Tab/LF/CR are shown as
    # real whitespace, so they never reach here.
    CONTROL_NAMES = {
      0x00 => "NUL", 0x01 => "SOH", 0x02 => "STX", 0x03 => "ETX", 0x04 => "EOT",
      0x05 => "ENQ", 0x06 => "ACK", 0x07 => "BEL", 0x08 => "BS",  0x0B => "VT",
      0x0C => "FF",  0x0E => "SO",  0x0F => "SI",  0x10 => "DLE", 0x11 => "DC1",
      0x12 => "DC2", 0x13 => "DC3", 0x14 => "DC4", 0x15 => "NAK", 0x16 => "SYN",
      0x17 => "ETB", 0x18 => "CAN", 0x19 => "EM",  0x1A => "SUB", 0x1B => "ESC",
      0x1C => "FS",  0x1D => "GS",  0x1E => "RS",  0x1F => "US",  0x7F => "DEL"
    }.freeze

    # Tooltip text explaining why a highlighted token is shown as an escape.
    def record_escape_title(token)
      if token == "\\\\"
        "Literal backslash, escaped as \\\\"
      elsif (match = token.match(/\A\\x(\h{2})\z/))
        byte = match[1].to_i(16)
        name = CONTROL_NAMES[byte]
        base = "Unprintable byte 0x#{match[1]}"
        name ? "#{base} (#{name})" : base
      else
        "Escaped byte"
      end
    end
  end
end
