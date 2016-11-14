module RocketJobMissionControl
  class ActiveProcessesController < RocketJobMissionControl::ApplicationController
    # The list of workers actively processing jobs
    # [Array[Array<server_name [String], job [RocketJob::Job], slice_id [String]]]
    def index
      busy = []

      RocketJob::ActiveServer.all.each_pair do |server_name, active_servers|
        active_servers.each do |as|
          busy << {
            server_name: as.name,
            klass:       as.job.class.name,
            description: as.job.description,
            started_at:  as.duration,
            id:          as.job.id
          }
        end
      end
      @busy = busy.sort_by { |h| h[:server_name] || '' }

      respond_to do |format|
        format.html
        format.json { render(json: ActiveProcessesDatatable.new(view_context, @busy)) }
      end
    end
  end
end
