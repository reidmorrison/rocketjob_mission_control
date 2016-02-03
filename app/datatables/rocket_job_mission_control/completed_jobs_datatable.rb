module RocketJobMissionControl
  class CompletedJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        [
          class_with_link(job),
          h(job.description.try(:truncate, 50)),
          h(job.duration),
          h(completed_ago(job))
        ]
      end
    end

    def sort_column(index)
      columns = %w[_type description duration completed_at]
      columns[index.to_i]
    end

    def completed_ago(job)
      "#{RocketJob.seconds_as_duration(Time.now - job.completed_at)} ago"
    end
  end
end
