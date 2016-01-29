module RocketJobMissionControl
  module Jobs
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_jobs
      before_filter :show_sidebar

      def running
        @jobs = @jobs.where(state: :running)
      end

      def paused
        @jobs = @jobs.where(state: :paused)
      end

      def completed
        @jobs = @jobs.where(state: :completed)
      end

      def aborted
        @jobs = @jobs.where(state: :aborted)
      end

      def failed
        @jobs = @jobs.where(state: :failed)
      end

      def queued
        @jobs = @jobs.queued_now
      end

      def scheduled
        @jobs = @jobs.scheduled
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
