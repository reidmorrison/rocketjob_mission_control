module RocketJobMissionControl
  module DirmonSanitizer
    DIRMON_FIELDS = %i(archive_directory job_class_name name pattern).freeze

    def self.sanitize(params, job_class, target)
      permissible_params = {}

      DIRMON_FIELDS.each do |field_name|
        value = params[field_name]
        next if value.blank?

        permissible_params[field_name] = value
      end

      if params.key?(:properties)
        properties                      = JobSanitizer.sanitize(params[:properties], job_class, target, false)
        permissible_params[:properties] = properties unless properties.blank?
      end

      permissible_params
    end

    # Returns [Hash] the difference between the supplied params and those already set in the job itself
    def self.diff_properties(sanitized_properties, dirmon_entry)
      default_job = dirmon_entry.job_class.new
      updated_job = dirmon_entry.job_class.from_properties(sanitized_properties)
      properties  = {}
      sanitized_properties&.each_pair do |name, value|
        if name == :input_categories
          categories = []
          value.each do |category_properties|
            category_name = category_properties[:name].to_sym
            props         = diff_category(category_properties, updated_job.input_category(category_name), default_job.input_category(category_name))
            categories << props unless props.empty?
          end
          properties[:input_categories] = categories unless categories.empty?
        elsif name == :output_categories
          categories = []
          value.each do |category_properties|
            category_name = category_properties[:name].to_sym
            props         = diff_category(category_properties, updated_job.output_category(category_name), default_job.output_category(category_name))
            categories << props unless props.empty?
          end
          properties[:output_categories] = categories unless categories.empty?
        elsif default_job.public_send(name) != updated_job.public_send(name)
          properties[name] = value.is_a?(String) ? value.gsub(/\r\n/, "\n") : value
        end
      end
      properties
    end

    def self.diff_category(properties, updated_category, default_category)
      diff = {}
      name = nil
      properties&.each_pair do |key, value|
        if key == :name
          name = value
          next
        end
        next if updated_category.public_send(key) == default_category.public_send(key)

        diff[key] = value
      end
      diff[:name] = name unless diff.empty?
      diff
    end
  end
end
