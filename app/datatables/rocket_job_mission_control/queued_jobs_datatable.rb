module RocketJobMissionControl
  class QueuedJobsDatatable < JobsDatatable
    DISPLAY_COLUMNS = %w[_type description priority queued_for]
    SORT_COLUMNS    = %w[_type description priority duration]

    private

    def map(job)
      {
        '0'           => class_with_link(job),
        '1'           => h(job.description.try(:truncate, 50)),
        '2'           => h(job.priority),
        '3'           => h(job.duration),
        '4'           => action_buttons(job),
        'DT_RowClass' => "card callout callout-#{job.state}"
      }
    end

    def sort_column(index)
      SORT_COLUMNS[index.to_i]
    end
  end
end
