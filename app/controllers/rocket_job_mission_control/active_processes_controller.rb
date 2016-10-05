module RocketJobMissionControl
  class ActiveProcessesController < RocketJobMissionControl::ApplicationController
    # The list of workers actively processing jobs
    # [Array[Array<worker_name [String], job [RocketJob::Job], slice_id [String]]]
    def index
      busy = []
      RocketJob::ActiveWorker.all.each do |worker_name, active_workers|
        active_workers.each do |aw|
          busy << {
            worker_name: worker_name,
            klass:       aw.job.class.name,
            description: aw.job.description,
            started_at:  aw.started_at,
            id:          aw.job.id
          }
        end
      end
      @busy = busy.sort_by { |h| h[:worker_name] || '' }

      respond_to do |format|
        format.html
        format.json { render(json: ActiveProcessesDatatable.new(view_context, @busy)) }
      end
    end
  end
end
