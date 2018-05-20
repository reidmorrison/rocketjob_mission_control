module RocketJobMissionControl
  class ActiveWorkersController < RocketJobMissionControl::ApplicationController
    def index
      authorize! :read, RocketJob::Worker
      @server_name = params[:server_name]
      if job_id = params[:job_id]
        @job = RocketJob::Job.find(job_id)
      end

      respond_to do |format|
        format.html
        format.json do
          # The list of workers actively processing jobs. Sorted by longest running workers first.
          active_workers =
            if @job
              @job.rocket_job_active_workers
            else
              RocketJob::ActiveWorker.all(@server_name).sort { |a, b| b.duration_s <=> a.duration_s }
            end

          query = RocketJobMissionControl::Query.new(active_workers)
          render(json: ActiveWorkersDatatable.new(view_context, query))
        end
      end
    end
  end
end
