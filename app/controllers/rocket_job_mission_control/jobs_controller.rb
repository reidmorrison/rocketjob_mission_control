module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    before_filter :find_job_or_redirect, except: [:index, :running]
    rescue_from StandardError, with: :error_occurred

    def running
      @jobs = RocketJob::Job.where(state: 'running')
    end

    def update
      @job.update_attributes!(job_params)

      redirect_to job_path(@job)
    end

    def abort
      @job.abort!

      redirect_to(job_path(@job))
    end

    def destroy
      if @job.completed? || @job.aborted?
        @job.destroy
        redirect_to(jobs_path)
      else
        flash[:alert] = "Cannot destroy a job unless it is completed or aborted"
        redirect_to(job_path(@job))
      end
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
      load_jobs
    end

    def index
      load_jobs
    end

    private

    def load_jobs
      @states = jobs_params
      @jobs = RocketJob::Job.limit(1000).sort(created_at: :desc)
      @jobs = @jobs.where(state: @states) unless @states.empty?
    end

    def find_job_or_redirect
      @job = RocketJob::Job.find(params[:id])

      if @job.nil?
        flash[:alert] = t(:failure, scope: [:job, :find], id: params[:id])

        redirect_to(jobs_path)
      end
    end

    def jobs_params
      params.fetch(:states, [])
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
