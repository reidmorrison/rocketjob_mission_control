module RocketJobMissionControl
  module Servers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def starting
        @servers = RocketJob::Server.starting.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @servers)) }
        end
      end

      def running
        @servers = RocketJob::Server.running.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @servers)) }
        end
      end

      def paused
        @servers = RocketJob::Server.paused.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @servers)) }
        end
      end

      def stopping
        @servers = RocketJob::Server.stopping.sort(name: 1)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @servers)) }
        end
      end

      private

      def show_sidebar
        @servers_sidebar = true
      end
    end
  end
end
