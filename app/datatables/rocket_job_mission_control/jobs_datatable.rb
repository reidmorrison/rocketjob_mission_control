module RocketJobMissionControl
  class JobsDatatable < AbstractDatatable
    delegate :job_path, :job_icon, :edit_job_path,
             :abort_job_path, :job_path, :fail_job_path, :run_now_job_path, :pause_job_path,
             :resume_job_path, :retry_job_path, :exception_job_path, :job_action_link, :exceptions_job_path, to: :@view

    COMMON_FIELDS = [:id, :_type, :description, :completed_at, :created_at, :started_at, :state].freeze

    ABORTED_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type', width: '30%'},
      {display: 'Description', value: :description, field: 'description', width: '30%'},
      {display: 'Aborted', value: :completed_ago, field: 'completed_at'},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]

    ALL_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type'},
      {display: 'Description', value: :description, field: 'description'},
      {display: 'Created', value: :created_at, field: 'created_at'},
      {display: 'Duration', value: :duration, field: 'duration', orderable: false},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]
    ALL_FIELDS  = COMMON_FIELDS + [:run_at].freeze

    COMPLETED_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type', width: '30%'},
      {display: 'Description', value: :description, field: 'description', width: '30%'},
      {display: 'Duration', value: :duration, field: 'duration', orderable: false},
      {display: 'Completed', value: :completed_ago, field: 'completed_at'},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]

    FAILED_COLUMNS              = ABORTED_COLUMNS.deep_dup
    FAILED_COLUMNS[2][:display] = 'Failed'

    PAUSED_COLUMNS              = ABORTED_COLUMNS.deep_dup
    PAUSED_COLUMNS[2][:display] = 'Paused'

    QUEUED_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type'},
      {display: 'Description', value: :description, field: 'description'},
      {display: 'Priority', value: :priority, field: 'priority'},
      {display: 'Queued For', value: :duration, field: 'duration', orderable: false},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]
    QUEUED_FIELDS  = COMMON_FIELDS + [:run_at, :priority].freeze

    RUNNING_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type'},
      {display: 'Description', value: :description, field: 'description'},
      {display: 'Progress', value: :progress, field: 'percent_complete', orderable: false},
      {display: 'Priority', value: :priority, field: 'priority'},
      {display: 'Started', value: :started, field: 'started_at'},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]
    RUNNING_FIELDS  = COMMON_FIELDS + [:record_count, :collect_output, :input_categories, :output_categories, :encrypt, :compress, :slice_size, :priority, :sub_state, :percent_complete].freeze

    SCHEDULED_COLUMNS = [
      {display: 'Class', value: :class_with_link, field: '_type'},
      {display: 'Description', value: :description, field: 'description'},
      {display: 'Runs in', value: :time_till_run, field: 'run_at'},
      {display: 'Cron Schedule', value: :cron_schedule, field: 'cron_schedule'},
      {display: 'Actions', value: :action_buttons, orderable: false}
    ]
    SCHEDULED_FIELDS  = COMMON_FIELDS + [:run_at, :cron_schedule].freeze

    def initialize(view, query, columns)
      @columns = columns
      super(view, query)
    end

    private

    def sort_column(index)
      @columns[index.to_i][:field]
    end

    # Map the values for each column
    def map(job)
      index = 0
      h     = {}
      @columns.each do |column|
        h[index.to_s] = send(column[:value], job)
        index         += 1
      end
      h['DT_RowClass'] = "card callout callout-#{job.state}"
      h
    end

    # Job View Helper methods
    def class_with_link(job)
      <<-EOS
        <a class='job-link' href="#{job_path(job.id)}">
          <i class="fa #{job_icon(job)}" style="font-size: 75%" title="#{job.state}"></i>
          #{job.class.name}
        </a>
      EOS
    end

    def description(job)
      h(job.description.try(:truncate, 50))
    end

    def duration(job)
      h(job.duration)
    end

    def created_at(job)
      h(job.created_at)
    end

    def priority(job)
      h(job.priority)
    end

    def started(job)
      "#{RocketJob.seconds_as_duration(Time.now - (job.started_at || Time.now))} ago" if job.started_at
    end

    def completed_ago(job)
      "#{RocketJob.seconds_as_duration(Time.now - (job.completed_at || Time.now))} ago"
    end

    def time_till_run(job)
      h(RocketJob.seconds_as_duration((job.run_at || Time.now) - Time.now))
    end

    def cron_schedule(job)
      h(job.cron_schedule) if job.respond_to?(:cron_schedule)
    end

    def progress(job)
      if (sub_state = job.attributes['sub_state']) && [:before, :after].include?(sub_state)
        <<-EOS
          <div class="job-status">
            <div class="job-state">
              <div class="left">Batch</div>
              <div class="right running">#{sub_state}</div>
            </div>
          </div>
        EOS
      else
        <<-EOS
          <div class='progress'>
            <div class='progress-bar' style="width: #{job.percent_complete}%;", title="#{job.percent_complete}% complete."></div>
          </div>
        EOS
      end
    end

    def action_buttons(job)
      events  = valid_events(job)
      buttons = "<div class='inline-job-actions'>"
      if job.scheduled?
        buttons += "#{ job_action_link('Run', run_now_job_path(job), :patch) }"
      end
      if events.include?(:pause)
        buttons += "#{ job_action_link('Pause', pause_job_path(job), :patch) }"
      end
      if events.include?(:resume)
        buttons += "#{ job_action_link('Resume', resume_job_path(job), :patch) }"
      end
      if events.include?(:retry)
        buttons += "#{ job_action_link('Retry', retry_job_path(job), :patch) }"
      end
      buttons += "#{ job_action_link('Destroy', job_path(job), :delete) }"
      buttons += "</div>"
    end

    def valid_events(job)
      job.aasm.events.collect(&:name)
    end

  end
end
