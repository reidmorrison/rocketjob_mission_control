module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    before_filter :find_job, only: [:abort, :retry, :update]

    def update
      @job.update_attributes!(job_params)

      redirect_to job_path(@job)
    end

    def abort
      @job.abort!

      redirect_to job_path(@job)
    end

    def retry
      @job.retry!

      redirect_to job_path(@job)
    end

    def show
      @jobs = RocketJob::Job.limit(1000).sort(created_at: :desc)
      @job = RocketJob::Job.find(params[:id])
    end

    def index
      @jobs = RocketJob::Job.limit(1000).sort(created_at: :desc)
    end

    private

    def find_job
      @job = RocketJob::Job.find(params[:id])
    end

    def job_params
      params.require(:job).permit(:priority)
    end

  end
end
