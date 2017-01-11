module RocketJobMissionControl
  class ScheduledJobsDatatable < JobsDatatable
    private

    def data(jobs)
      jobs.map do |job|
        {
          '0' => class_with_link(job),
          '1' => h(job.description.try(:truncate, 50)),
          '2' => h(time_till_run(job)),
          '3' => h(cron_schedule(job)),
          '4' => action_buttons(job),
          'DT_RowClass' => "card callout callout-#{job.state}"
        }
      end
    end

    def sort_column(index)
      columns = %w[_type description run_at cron_schedule]
      columns[index.to_i]
    end

    def time_till_run(job)
      RocketJob.seconds_as_duration(job.run_at - Time.now)
    end

    def cron_schedule(job)
      job.cron_schedule if job.respond_to?(:cron_schedule)
    end
  end
end
