module RocketJobMissionControl
  class ActiveWorkersController < RocketJobMissionControl::ApplicationController
    # The list of workers actively processing jobs
    # [Array[Array<server_name [String], job [RocketJob::Job], slice_id [String]]]
    def index
      # Sorted by longest running workers first
      @active_workers = RocketJob::ActiveWorker.all.sort { |a, b| b.duration_s <=> a.duration_s }
      @query          = RocketJobMissionControl::Query.new(@active_workers)

      respond_to do |format|
        format.html
        format.json { render(json: ActiveWorkersDatatable.new(view_context, @query)) }
      end
    end
  end
end
