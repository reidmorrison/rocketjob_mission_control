module RocketJobMissionControl
  module Jobs
    class Search
      attr_reader :results, :search_term

      def initialize(search_term, search_subset)
        @search_term = search_term
        @results = search_subset
      end

      def execute
        if !search_term.blank?
          @results = @results.where('$or' => [{_type: /#{search_term}/},{ description: /#{search_term}/}] )
        end
        @results
      end
    end
  end
end
