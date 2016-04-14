module RocketJobMissionControl
  class RunningJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        {
          '0' => class_with_link(job),
          '1' => h(job.description.try(:truncate, 50)),
          '2' => progress(job),
          '3' => h(job.priority),
          '4' => h(started(job)),
          '5' => action_buttons(job),
          'DT_RowClass' => "card callout callout-#{job.state}"
        }
      end
    end

    def sort_column(index)
      columns = %w[_type description percent_complete priority started_at]
      columns[index.to_i]
    end

    def progress(job)
      <<-EOS
        <div class='progress'>
          <div class='progress-bar' style="width: #{job.percent_complete}%;", title="#{job.percent_complete}% complete."></div>
        </div>
      EOS
    end

    def started(job)
      "#{RocketJob.seconds_as_duration(Time.now - job.started_at)} ago" if job.started_at
    end
  end
end
