module RocketJobMissionControl
  class QueuedJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        [
          class_with_link(job),
          h(job.description.try(:truncate, 50)),
          h(job.priority),
          h(job.duration)
        ]
      end
    end

    def sort_column(index)
      columns = %w[_type description priority duration]
      columns[index.to_i]
    end
  end
end
