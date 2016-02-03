module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_jobs
      before_filter :show_sidebar

      def running
        @jobs = @jobs.where(state: :running)
        respond_to do |format|
          format.html
          format.json { render(json: RunningJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def paused
        @jobs = @jobs.where(state: :paused)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def completed
        @jobs = @jobs.where(state: :completed)
        respond_to do |format|
          format.html
          format.json { render(json: CompletedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def aborted
        @jobs = @jobs.where(state: :aborted)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def failed
        @jobs = @jobs.where(state: :failed)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def queued
        @jobs = @jobs.queued_now
        respond_to do |format|
          format.html
          format.json { render(json: QueuedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def scheduled
        @jobs = @jobs.scheduled
        respond_to do |format|
          format.html
          format.json { render(json: ScheduledJobsDatatable.new(view_context, @jobs)) }
        end
      end

      private

      def load_jobs
        @jobs = RocketJob::Job.sort(_id: :desc).limit(1000)
      end

      def show_sidebar
        @jobs_sidebar = true
      end
    end
  end
end
