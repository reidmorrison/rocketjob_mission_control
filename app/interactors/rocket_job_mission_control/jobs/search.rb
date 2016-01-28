module RocketJobMissionControl
  module Jobs
    class Search
      attr_reader :results, :search_term, :states

      def initialize(search_term, states)
        @search_term = search_term
        @states      = states
      end

      def execute
        results = RocketJob::Job.limit(1000).sort(created_at: :desc)

        if !search_term.blank?
          results = results.where('$or' => [{_type: /#{search_term}/},{ description: /#{search_term}/}] )
        end

        if !states.empty?
          results = results.where(state: states)
        end

        results
      end

      private

      attr_writer :results
    end
  end
end
