module RocketJobMissionControl
  module DirmonEntries
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :show_sidebar

      def pending
        @dirmons = RocketJob::DirmonEntry.pending
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def enabled
        @dirmons = RocketJob::DirmonEntry.enabled
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def failed
        @dirmons = RocketJob::DirmonEntry.failed
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def disabled
        @dirmons = RocketJob::DirmonEntry.disabled
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      private

      def show_sidebar
        @dirmon_sidebar = true
      end
    end
  end
end
