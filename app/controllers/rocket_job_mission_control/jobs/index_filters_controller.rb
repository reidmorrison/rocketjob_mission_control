module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      COMMON_FIELDS    = [:id, :_type, :description, :completed_at, :created_at, :started_at, :state].freeze
      RUNNING_FIELDS   = COMMON_FIELDS + [:record_count, :collect_output, :input_categories, :output_categories, :encrypt, :compress, :slice_size, :priority, :sub_state, :percent_complete].freeze
      QUEUED_FIELDS    = COMMON_FIELDS + [:run_at, :priority].freeze
      SCHEDULED_FIELDS = COMMON_FIELDS + [:run_at, :cron_schedule].freeze

      def running
        @jobs                  = RocketJob::Job.running.only(RUNNING_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, started_at: :desc)
        @query.display_columns = RunningJobsDatatable::DISPLAY_COLUMNS

        respond_to do |format|
          format.html
          format.json { render(json: RunningJobsDatatable.new(view_context, @query)) }
        end
      end

      def paused
        @jobs                  = RocketJob::Job.paused.only(COMMON_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, completed_at: :desc)
        @query.display_columns = InterruptedJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @query)) }
        end
      end

      def completed
        @jobs                  = RocketJob::Job.completed.only(COMMON_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, completed_at: :desc)
        @query.display_columns = CompletedJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: CompletedJobsDatatable.new(view_context, @query)) }
        end
      end

      def aborted
        @jobs                  = RocketJob::Job.aborted.only(COMMON_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, completed_at: :desc)
        @query.display_columns = InterruptedJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @query)) }
        end
      end

      def failed
        @jobs                  = RocketJob::Job.failed.only(COMMON_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, completed_at: :desc)
        @query.display_columns = InterruptedJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: InterruptedJobsDatatable.new(view_context, @query)) }
        end
      end

      def queued
        @jobs                  = RocketJob::Job.queued_now.only(QUEUED_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, completed_at: :desc)
        @query.display_columns = QueuedJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: QueuedJobsDatatable.new(view_context, @query)) }
        end
      end

      def scheduled
        @jobs                  = RocketJob::Job.scheduled.only(SCHEDULED_FIELDS)
        @query                 = RocketJobMissionControl::Query.new(@jobs, run_at: :asc)
        @query.display_columns = ScheduledJobsDatatable::DISPLAY_COLUMNS
        respond_to do |format|
          format.html
          format.json { render(json: ScheduledJobsDatatable.new(view_context, @query)) }
        end
      end

      private

      def show_sidebar
        @jobs_sidebar = true
      end

    end
  end
end
