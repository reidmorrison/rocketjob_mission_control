module RocketJobMissionControl
  module DirmonEntries
    class IndexFiltersController < RocketJobMissionControl::ApplicationController
      before_filter :load_dirmon_entries
      before_filter :show_sidebar

      def pending
        @dirmons = @dirmons.where(state: :pending)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def enabled
        @dirmons = @dirmons.where(state: :enabled)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def failed
        @dirmons = @dirmons.where(state: :failed)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      def disabled
        @dirmons = @dirmons.where(state: :disabled)
        respond_to do |format|
          format.html
          format.json { render(json: DirmonEntriesDatatable.new(view_context, @dirmons)) }
        end
      end

      private

      def load_dirmon_entries
        @dirmons = RocketJob::DirmonEntry.all
      end

      def show_sidebar
        @dirmon_sidebar = true
      end
    end
  end
end
