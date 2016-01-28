module RocketJobMissionControl
  class ActiveProcessesController < RocketJobMissionControl::ApplicationController
    def index
      # The list of workers actively processing jobs
      # [Array[Array<worker_name [String], job [RocketJob::Job], slice_id [String]]]
      sorted = true
      t      = Time.new
      busy   = []
      RocketJob::Job.running.sort(:worker_name).collect do |job|
        if job.respond_to?(:input_categories)
          sorted = false
          job.input.each('state' => 'running') do |slice|
            busy << [slice.worker_name, job, slice.started_at]
          end
        else
          busy << [job.worker_name, job, job.started_at]
        end
      end
      @busy = sorted ? busy : busy.sort_by { |result| result.first }
    end
  end
end
