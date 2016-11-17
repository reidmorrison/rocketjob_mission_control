module RocketJobMissionControl
  class ActiveWorkersController < RocketJobMissionControl::ApplicationController
    # The list of workers actively processing jobs
    # [Array[Array<server_name [String], job [RocketJob::Job], slice_id [String]]]
    def index
      @active_workers = RocketJob::ActiveWorker.all.sort_by(&:name)

      respond_to do |format|
        format.html
        format.json { render(json: ActiveWorkersDatatable.new(view_context, @active_workers)) }
      end
    end
  end
end
