module RocketJobMissionControl
  module Workers
    class Search
      attr_reader :results, :search_term

      def initialize(search_term, search_subset)
        @search_term = Regexp.escape(search_term)
        @results     = search_subset
      end

      def execute
        if !search_term.blank?
          @results = @results.where('$or' => [{name: /#{search_term}/i}])
        end
        @results
      end
    end
  end
end
