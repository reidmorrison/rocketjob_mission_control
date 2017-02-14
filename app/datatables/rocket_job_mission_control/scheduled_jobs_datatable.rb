module RocketJobMissionControl
  class ScheduledJobsDatatable < JobsDatatable
    DISPLAY_COLUMNS = %w[_type description runs_in cron_schedule]
    SORT_COLUMNS    = %w[_type description run_at cron_schedule]

    private

    def map(job)
      {
        '0'           => class_with_link(job),
        '1'           => h(job.description.try(:truncate, 50)),
        '2'           => h(time_till_run(job)),
        '3'           => h(cron_schedule(job)),
        '4'           => action_buttons(job),
        'DT_RowClass' => "card callout callout-#{job.state}"
      }
    end

    def sort_column(index)
      SORT_COLUMNS[index.to_i]
    end

    def time_till_run(job)
      RocketJob.seconds_as_duration(job.run_at - Time.now)
    end

    def cron_schedule(job)
      job.cron_schedule if job.respond_to?(:cron_schedule)
    end
  end
end
