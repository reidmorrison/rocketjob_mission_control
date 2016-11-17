module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      REQUIRED_FIELDS = [:id, :_type, :description, :completed_at, :created_at, :started_at, :state]

      def running
        @jobs = RocketJob::Job.running.only(:record_count, :collect_output, :input_categories, :encrypt, :compress, :slice_size, :priority, :sub_state, REQUIRED_FIELDS).sort(started_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: RunningJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def paused
        @jobs = RocketJob::Job.paused.only(REQUIRED_FIELDS).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def completed
        @jobs = RocketJob::Job.completed.only(REQUIRED_FIELDS).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: CompletedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def aborted
        @jobs = RocketJob::Job.aborted.only(REQUIRED_FIELDS).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def failed
        @jobs = RocketJob::Job.failed.only(REQUIRED_FIELDS).sort(completed_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def queued
        @jobs = RocketJob::Job.queued_now.only(:run_at, :priority, REQUIRED_FIELDS).sort(created_at: :desc)
        respond_to do |format|
          format.html
          format.json { render(json: QueuedJobsDatatable.new(view_context, @jobs)) }
        end
      end

      def scheduled
        @jobs = RocketJob::Job.scheduled.only(:run_at, :cron_schedule, REQUIRED_FIELDS).sort(run_at: :asc)
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
