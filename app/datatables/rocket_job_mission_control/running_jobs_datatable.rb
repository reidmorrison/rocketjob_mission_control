module RocketJobMissionControl
  class RunningJobsDatatable < JobsDatatable
    private

    def data
      jobs.map do |job|
        [
          class_with_link(job),
          h(job.description.try(:truncate, 50)),
          progress(job),
          h(job.priority),
          h(started(job))
        ]
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
