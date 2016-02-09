module RocketJobMissionControl
  class QueuedJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        {
          '0' => class_with_link(job),
          '1' => h(job.description.try(:truncate, 50)),
          '2' => h(job.priority),
          '3' => h(job.duration),
          'DT_RowClass' => "card callout callout-#{job.state}"
        }
      end
    end

    def sort_column(index)
      columns = %w[_type description priority duration]
      columns[index.to_i]
    end
  end
end
