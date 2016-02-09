module RocketJobMissionControl
  module DirmonEntries
    class Search
      attr_reader :results, :search_term

      def initialize(search_term, search_subset)
        @search_term = search_term
        @results = search_subset
      end

      def execute
        if !search_term.blank?
          @results = @results.where('$or' => [{job_class_name: /#{search_term}/},{ name: /#{search_term}/},{ pattern: /#{search_term}/}] )
        end
        @results
      end
    end
  end
end
