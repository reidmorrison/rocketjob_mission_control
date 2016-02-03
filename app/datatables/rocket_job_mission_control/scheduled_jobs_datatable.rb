module RocketJobMissionControl
  class ScheduledJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        [
          class_with_link(job),
          h(job.description.try(:truncate, 50)),
          h(time_till_run(job)),
          h(cron_schedule(job))
        ]
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
