module RocketJobMissionControl
  module DirmonSanitizer
    DIRMON_FIELDS = %w(archive_directory job_class_name name pattern).freeze

    def self.sanitize(params, job_class)
      permissible_params = {}

      DIRMON_FIELDS.each do |field_name|
        next unless value = params[field_name]
        permissible_params[field_name] = value.blank? ? nil : value
      end

      if params.key?(:properties)
        permissible_params[:properties] = JobSanitizer.sanitize(params[:properties], job_class, true)
      end

      permissible_params
    end
  end
end
