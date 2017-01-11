module RocketJobMissionControl
  module DirmonEntries
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def pending
        @query = RocketJobMissionControl::Query.new(RocketJob::DirmonEntry.pending, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @query)) }
        end
      end

      def enabled
        @query = RocketJobMissionControl::Query.new(RocketJob::DirmonEntry.enabled, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @query)) }
        end
      end

      def failed
        @query = RocketJobMissionControl::Query.new(RocketJob::DirmonEntry.failed, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @query)) }
        end
      end

      def disabled
        @query = RocketJobMissionControl::Query.new(RocketJob::DirmonEntry.disabled, name: :asc)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @query)) }
        end
      end

      private

      def show_sidebar
        @dirmon_sidebar = true
      end
    end
  end
end
