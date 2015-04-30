module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    before_filter :find_job_or_redirect, except: [:index]
    rescue_from StandardError, with: :error_occurred

    def update
      @job.update_attributes!(job_params)

      redirect_to job_path(@job)
    end

    def abort
      @job.abort!

      redirect_to(job_path(@job))
    end

    def retry
      @job.retry!

      redirect_to(job_path(@job))
    end

    def pause
      @job.pause!

      redirect_to(job_path(@job))
    end

    def resume
      @job.resume!

      redirect_to(job_path(@job))
    end

    def fail
      @job.fail!

      redirect_to(job_path(@job))
    end

    def show
      @jobs = RocketJob::Job.limit(1000).sort(created_at: :desc)
    end

    def index
      @jobs = RocketJob::Job.limit(1000).sort(created_at: :desc)
    end

    private

    def find_job_or_redirect
      @job = RocketJob::Job.find(params[:id])

      if @job.nil?
        flash[:alert] = t(:failure, scope: [:job, :find], id: params[:id])

        redirect_to(jobs_path)
      end
    end

    def job_params
      params.require(:job).permit(:priority)
    end

    def error_occurred(exception)
      logger.error "Error loading a job", exception
      flash[:danger] = "Error loading jobs."
      raise exception if Rails.env.development?
      redirect_to :back
    end
  end
end
