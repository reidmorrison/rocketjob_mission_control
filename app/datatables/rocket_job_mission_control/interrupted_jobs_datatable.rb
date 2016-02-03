module RocketJobMissionControl
  class FailedJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        [
          class_with_link(job),
          h(job.description.try(:truncate, 50)),
          h(interrupted_ago(job))
        ]
      end
    end

    def sort_column(index)
      columns = %w[_type description completed_at]
      columns[index.to_i]
    end

    def interrupted_ago(job)
      "#{RocketJob.seconds_as_duration(Time.now - job.completed_at)} ago"
    end
  end
end
