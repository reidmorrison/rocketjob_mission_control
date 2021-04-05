module RocketJobMissionControl
  module DirmonEntriesHelper
    def dirmon_counts_by_state(state)
      RocketJob::DirmonEntry.counts_by_state.fetch(state.downcase.to_sym, 0)
    end


    def dirmon_entry_find_category(categories, category_name = :main)
      return unless categories

      categories.each { |category| return category if category_name == (category["name"] || :main).to_sym }
      nil
    end
  end
end
