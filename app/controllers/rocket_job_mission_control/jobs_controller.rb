module RocketJobMissionControl
  class JobsController < ApplicationController
    before_filter :find_job, only: [:set_priority, :download, :retry]

    def set_priority
      @job.priority = params[:priority]
      @job.save

      respond_to do |format|
        format.html { redirect_to job_path(@job) }
        format.js
      end
    end

    def retry
      @job.retry!

      respond_to do |format|
        format.html { redirect_to job_path(@job) }
        format.js
      end
    end

    def show
      @jobs = RocketJob::Job.sort(created_at: :desc)
      @job = RocketJob::Job.find(params[:id])

      respond_to do |format|
        format.html
        format.js { render :index }
      end
    end

    def index
      @jobs = RocketJob::Job.sort(created_at: :desc)

      respond_to do |format|
        format.html
        format.js
      end
    end

    private

    def find_job
      @job = RocketJob::Job.find(params[:id])
    end

  end
end
