module RocketJobMissionControl
  module DirmonSanitizer
    DIRMON_FIELDS = %i(archive_directory job_class_name name pattern).freeze

    def self.sanitize(params, job_class, target)
      permissible_params = {}

      DIRMON_FIELDS.each do |field_name|
        next unless value = params[field_name]
        permissible_params[field_name] = value unless value.blank?
      end

      if params.key?(:properties)
        properties = JobSanitizer.sanitize(params[:properties], job_class, target, false)
        permissible_params[:properties] = properties unless properties.blank?
      end

      permissible_params
    end
  end
end
