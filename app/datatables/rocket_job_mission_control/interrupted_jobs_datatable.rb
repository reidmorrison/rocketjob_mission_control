module RocketJobMissionControl
  class InterruptedJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        {
          '0' => class_with_link(job),
          '1' => h(job.description.try(:truncate, 50)),
          '2' => h(interrupted_ago(job)),
          '3' => action_buttons(job),
          'DT_RowClass' => "card callout callout-#{job.state}"
        }
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
