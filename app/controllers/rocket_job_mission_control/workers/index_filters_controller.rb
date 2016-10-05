module RocketJobMissionControl
  module Workers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def starting
        @workers = RocketJob::Worker.starting.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def running
        @workers = RocketJob::Worker.running.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def paused
        @workers = RocketJob::Worker.paused.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def stopping
        @workers = RocketJob::Worker.stopping.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      private

      def show_sidebar
        @workers_sidebar = true
      end
    end
  end
end
