module RocketJobMissionControl
  module Workers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_workers
      before_filter :show_sidebar

      def starting
        @workers = @workers.where(state: :starting).to_a
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def running
        @workers = @workers.where(state: :running).to_a
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def paused
        @workers = @workers.where(state: :paused).to_a
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def stopping
        @workers = @workers.where(state: :stopping).to_a
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, @workers)) }
        end
      end

      def zombies
        data = []
        @workers.each {|worker| data << worker if worker.zombie?}
        respond_to do |format|
          format.html
          format.json { render(json: WorkersDatatable.new(view_context, data)) }
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
