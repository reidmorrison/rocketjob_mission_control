module RocketJobMissionControl
  module Servers
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def starting
        @servers = RocketJob::Server.starting
        @query   = RocketJobMissionControl::Query.new(@servers, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @query)) }
        end
      end

      def running
        @servers = RocketJob::Server.running
        @query   = RocketJobMissionControl::Query.new(@servers, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @query)) }
        end
      end

      def paused
        @servers = RocketJob::Server.paused
        @query   = RocketJobMissionControl::Query.new(@servers, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @query)) }
        end
      end

      def stopping
        @servers = RocketJob::Server.stopping
        @query   = RocketJobMissionControl::Query.new(@servers, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: ServersDatatable.new(view_context, @query)) }
        end
      end

      private

      def show_sidebar
        @servers_sidebar = true
      end
    end
  end
end
