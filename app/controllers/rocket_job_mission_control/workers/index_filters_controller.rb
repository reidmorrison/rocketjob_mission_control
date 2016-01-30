module RocketJobMissionControl
  module Workers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_workers
      before_filter :show_sidebar

      def starting
        @workers = @workers.where(state: :starting)
      end

      def running
        @workers = @workers.where(state: :running)
      end

      def paused
        @workers = @workers.where(state: :paused)
      end

      def stopping
        @workers = @workers.where(state: :stopping)
      end

      private

      def load_workers
        @workers = RocketJob::Worker.sort(:name)
      end

      def show_sidebar
        @workers_sidebar = true
      end
    end
  end
end
