module RocketJobMissionControl
  class JobsDatatable < AbstractDatatable
    delegate :job_path, :job_icon, :edit_job_path,
      :abort_job_path, :job_path, :fail_job_path, :run_now_job_path, :pause_job_path,
      :resume_job_path, :retry_job_path, :job_failures_path, :job_action_link, :exceptions_job_path, to: :@view

    def initialize(view, query)
      query.search_columns = [:_type, :description]
      super(view, query)
    end

    private

    def map(job)
      {
        '0'           => class_with_link(job),
        '1'           => h(job.description.try(:truncate, 50)),
        '2'           => h(job.created_at),
        '3'           => h(job.duration),
        '4'           => action_buttons(job),
        'DT_RowClass' => "card callout callout-#{job.state}"
      }
    end

    def class_with_link(job)
      <<-EOS
        <a class='job-link' href="#{job_path(job.id)}">
          <i class="fa #{job_icon(job)}" style="font-size: 75%" title="#{job.state}"></i>
          #{job.class.name}
        </a>
      EOS
    end

    def action_buttons(job)
      events  = valid_events(job)
      buttons = "<div class='inline-job-actions'>"
      if job.scheduled?
        buttons += "#{ job_action_link('Run', run_now_job_path(job), :patch) }"
      end
      if events.include?(:pause)
        buttons += "#{ job_action_link('Pause', pause_job_path(job), :patch) }"
      end
      if events.include?(:resume)
        buttons += "#{ job_action_link('Resume', resume_job_path(job), :patch) }"
      end
      if events.include?(:retry)
        buttons += "#{ job_action_link('Retry', retry_job_path(job), :patch) }"
      end
      buttons += "#{ job_action_link('Destroy', job_path(job), :delete) }"
      buttons += "</div>"
    end

    def valid_events(job)
      job.aasm.events.collect(&:name)
    end

  end
end
