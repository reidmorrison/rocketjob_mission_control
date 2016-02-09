module RocketJobMissionControl
  module Workers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_workers
      before_filter :show_sidebar

      def starting
        @workers = @workers.where(state: :starting)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def running
        @workers = @workers.where(state: :running)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def paused
        @workers = @workers.where(state: :paused)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def stopping
        @workers = @workers.where(state: :stopping)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
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
