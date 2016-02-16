module RocketJobMissionControl
  module DirmonEntriesHelper
    def dirmon_counts_by_state(state)
      RocketJob::DirmonEntry.counts_by_state.fetch(state.downcase.to_sym, 0)
    end
  end
end
