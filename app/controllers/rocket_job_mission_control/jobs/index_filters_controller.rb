module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def running
        @jobs = RocketJob::Job.where(state: :running).sort(started_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: RunningJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def paused
        @jobs = RocketJob::Job.where(state: :paused).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def completed
        @jobs = RocketJob::Job.where(state: :completed).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: CompletedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def aborted
        @jobs = RocketJob::Job.where(state: :aborted).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def failed
        @jobs = RocketJob::Job.where(state: :failed).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def queued
        @jobs = RocketJob::Job.queued_now.sort(created_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: QueuedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def scheduled
        @jobs = RocketJob::Job.scheduled.sort(run_at: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: ScheduledJobsDatatable.new(view_context, @jobs)) }
        end
      end

      private

      def show_sidebar
        @jobs_sidebar = true
      end
    end
  end
end
