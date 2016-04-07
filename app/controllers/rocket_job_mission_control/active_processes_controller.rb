module RocketJobMissionControl
  class ActiveProcessesController < RocketJobMissionControl::ApplicationController
    def index
      # The list of workers actively processing jobs
      # [Array[Array<worker_name [String], job [RocketJob::Job], slice_id [String]]]
      sorted = true
      busy   = []
      # Need paused, failed or aborted since workers may still be working on active slices
      RocketJob::Job.where(state: [:running, :paused, :failed, :aborted]).sort(:worker_name).collect do |job|
        if job.respond_to?(:input) && job.sub_state == :processing
          sorted = false
          job.input.each('state' => 'running') do |slice|
            busy << {worker_name: slice.worker_name, klass: job.class.name, description: job.description, started_at: slice.started_at, id: job.id}
          end
        elsif job.running?
          busy << {worker_name: job.worker_name, klass: job.class.name, description: job.description, started_at: job.started_at, id: job.id}
        end
      end
      @busy = sorted ? busy : busy.sort_by { |h| h[:worker_name] }

      respond_to do |format|
        format.html
        format.json { render(json: ActiveProcessesDatatable.new(view_context, @busy)) }
      end
    end
  end
end
