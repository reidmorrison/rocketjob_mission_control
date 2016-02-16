module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    before_filter :find_job_or_redirect, except: [:index]
    before_filter :show_sidebar
    rescue_from StandardError, with: :error_occurred

    def index
      @jobs  = RocketJob::Job.sort(_id: :desc)
      respond_to do |format|
        format.html
        format.json { render(json: JobsDatatable.new(view_context, @jobs)) }
      end
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
        flash[:alert] = 'Cannot destroy a job unless it is completed or aborted'
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

    def run_now
      @job.update_attribute(:run_at, nil) if @job.scheduled?
      redirect_to scheduled_jobs_path
    end

    def fail
      @job.fail!

      redirect_to(job_path(@job))
    end

    def show
    end

    private

    def show_sidebar
      @jobs_sidebar = true
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
      if defined?(SemanticLogger::Logger) && logger.is_a?(SemanticLogger::Logger)
        logger.error 'Error loading a job', exception
      else
        logger.error "Error loading a job. #{log.exception.class}: #{log.exception.message}\n#{(log.exception.backtrace || []).join("\n")}"
      end
      flash[:danger] = 'Error loading jobs.'
      raise exception if Rails.env.development?
      redirect_to :back
    end
  end
end
