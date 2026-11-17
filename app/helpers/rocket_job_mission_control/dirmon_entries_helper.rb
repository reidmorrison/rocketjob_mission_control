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

    # Returns [RocketJob::Job] the job that the entry's properties build, whose values its form shows, or nil without a
    # job class. Returns nil too when Rocket Job cannot build one from them, such as for a category that the job class
    # does not define or an option that it no longer has, and adds why to the entry's errors, so that its form still
    # shows its other attributes rather than failing.
    def dirmon_entry_job(dirmon_entry)
      job_class = dirmon_entry.job_class
      job_class&.from_properties(dirmon_entry.properties)
    rescue ArgumentError, NoMethodError, Mongoid::Errors::MongoidError => e
      reason = e.respond_to?(:problem) ? e.problem : e.message
      dirmon_entry.errors.add(:properties, "cannot build a #{job_class.name}, so they cannot be edited here: #{reason}")
      nil
    end

    def rocket_job_mission_control
      @@rocket_job_mission_control_engine_url_helpers ||= RocketJobMissionControl::Engine.routes.url_helpers
    end
  end
end
