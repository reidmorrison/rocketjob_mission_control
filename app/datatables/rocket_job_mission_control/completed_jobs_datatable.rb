module RocketJobMissionControl
  class CompletedJobsDatatable < JobsDatatable
    DISPLAY_COLUMNS = %w[_type description duration completed_at]
    SORT_COLUMNS    = %w[_type description machine_duration completed_at]

    private

    def map(job)
      {
        '0'           => class_with_link(job),
        '1'           => h(job.description.try(:truncate, 50)),
        '2'           => h(job.duration),
        '3'           => h(completed_ago(job)),
        '4'           => action_buttons(job),
        'DT_RowClass' => "card callout callout-#{job.state}"
      }
    end

    def sort_column(index)
      SORT_COLUMNS[index.to_i]
    end

    def completed_ago(job)
      "#{RocketJob.seconds_as_duration(Time.now - job.completed_at)} ago"
    end
  end
end
