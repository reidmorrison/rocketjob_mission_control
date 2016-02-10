module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def running
        running_jobs = RocketJob::Job.where(state: :running)
        respond_to do |format|
          format.html
          format.json { render(json: RunningJobsDatatable.new(view_context, running_jobs)) }
        end
      end

      def paused
        paused_jobs = RocketJob::Job.where(state: :paused)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, paused_jobs)) }
        end
      end

      def completed
        completed_jobs = RocketJob::Job.where(state: :completed)
        respond_to do |format|
          format.html
          format.json { render(json: CompletedJobsDatatable.new(view_context, completed_jobs)) }
        end
      end

      def aborted
        aborted_jobs = RocketJob::Job.where(state: :aborted)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, aborted_jobs)) }
        end
      end

      def failed
        failed_jobs = RocketJob::Job.where(state: :failed)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, failed_jobs)) }
        end
      end

      def queued
        queued_jobs = RocketJob::Job.queued_now
        respond_to do |format|
          format.html
          format.json { render(json: QueuedJobsDatatable.new(view_context, queued_jobs)) }
        end
      end

      def scheduled
        scheduled_jobs = RocketJob::Job.scheduled
        respond_to do |format|
          format.html
          format.json { render(json: ScheduledJobsDatatable.new(view_context, scheduled_jobs)) }
        end
      end

      private

      def show_sidebar
        @jobs_sidebar = true
      end
    end
  end
end
