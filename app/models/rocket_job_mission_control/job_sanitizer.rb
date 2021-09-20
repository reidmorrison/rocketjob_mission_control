module RocketJobMissionControl
  module JobSanitizer
    CATEGORIES_FIELDS = %i[id name format format_options mode skip_unknown slice_size columns].freeze

    # Returns [Hash] the permissible params for the specified job class, after sanitizing.
    # Parameters
    #   properties [Hash]
    #     Parameters to extract the values from.
    #
    #   job_class [RocketJob::Job]
    #     Job class from which the user editable fields and types will be retrieved.
    #
    #   target [ActiveModel::Base]
    #     Model to set the errors on.
    #
    #   nil_blank [Boolean]
    #     true: Nil out blank fields.
    #     false: Do not return blank fields.
    #     Default: true
    def self.sanitize(properties, job_class, target, nil_blank = true)
      permissible_params = {}

      job_class.user_editable_fields.each do |field_name|
        next unless value = properties[field_name]

        field = job_class.fields[field_name.to_s]
        next unless field&.type

        case field.type.name
        when "String"
          value.gsub(/\r\n/, "\n")
        when "Hash"
          begin
            value = value.blank? ? nil : JSON.parse(value)
          rescue JSON::ParserError => e
            target.errors.add(:properties, e.message)
            value = nil
          end
        end

        if value.blank? && !value.is_a?(Hash)
          permissible_params[field_name] = nil if nil_blank
        else
          permissible_params[field_name] = value
        end
      end

      if properties.key?(:input_categories_attributes)
        categories                            = sanitize_categories(properties[:input_categories_attributes])
        permissible_params[:input_categories] = categories unless categories == [{}]
      end

      if properties.key?(:output_categories_attributes)
        categories                             = sanitize_categories(properties[:output_categories_attributes])
        permissible_params[:output_categories] = categories unless categories == [{}]
      end

      permissible_params
    end

    def self.sanitize_categories(properties)
      categories = []

      properties.each_pair do |_, category|
        hash = {}
        CATEGORIES_FIELDS.each do |key|
          next unless category.key?(key)

          value = category[key]
          next if value.blank?
          next if (key == :columns) && value == [""]

          value     = JSON.parse(value) if key == :format_options
          hash[key] = value
        end
        categories << hash
      end

      categories
    end
  end
end
