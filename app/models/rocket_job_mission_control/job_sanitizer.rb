module RocketJobMissionControl
  module JobSanitizer
    CATEGORIES_FIELDS = %i[id name format format_options schema encoding invalid_characters mode skip_unknown
                           slice_size columns].freeze

    # The category fields whose blank value means their default, nil, such as the UTF-8 of an `encoding` that is
    # left blank, or no `schema`, so that blanking them clears a value that was set.
    CLEARABLE_CATEGORY_FIELDS = %i[schema encoding invalid_characters].freeze

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
        next unless (value = properties[field_name])

        field = job_class.fields[field_name.to_s]
        next unless field&.type

        case field.type.name
        when "String"
          value.gsub("\r\n", "\n")
        when "Hash"
          begin
            value = value.blank? ? nil : JSON.parse(value)
          rescue JSON::ParserError => e
            target.errors.add(:properties, e.message)
            value = nil
          end
        when "Array"
          # remove blank entries from rails converted arrays when using multi-select input
          value.presence&.reject!(&:empty?)
        end

        if value.blank? && !value.is_a?(Hash)
          permissible_params[field_name] = nil if nil_blank
        else
          permissible_params[field_name] = value
        end
      end

      if properties.key?(:input_categories_attributes)
        categories = sanitize_categories(properties[:input_categories_attributes], nil_blank, target)
        permissible_params[:input_categories] = categories unless categories == [{}]
      end

      if properties.key?(:output_categories_attributes)
        categories = sanitize_categories(properties[:output_categories_attributes], nil_blank, target)
        permissible_params[:output_categories] = categories unless categories == [{}]
      end

      permissible_params
    end

    # Returns [Array<Hash>] the permissible properties of each category, see .sanitize for `nil_blank`, which only
    # applies to the CLEARABLE_CATEGORY_FIELDS, and `target`, which gets the error of a schema that is not valid JSON.
    def self.sanitize_categories(properties, nil_blank = true, target = nil)
      categories = []

      properties.each_pair do |_, category|
        hash = {}
        CATEGORIES_FIELDS.each do |key|
          next unless category.key?(key)

          value = category[key]
          if value.blank?
            hash[key] = nil if nil_blank && CLEARABLE_CATEGORY_FIELDS.include?(key)
            next
          end
          next if (key == :columns) && value == [""]

          value = JSON.parse(value) if key == :format_options
          if key == :schema
            value = sanitize_schema(value, target)
            next if value.nil?
          end
          hash[key] = value
        end
        categories << hash
      end

      categories
    end

    # Returns [Hash|String] the schema of a category as its form gives it, see RocketJob::Category::Base#schema: the
    # JSON of a schema, which is parsed, or the path or url of the JSON file that holds it.
    # Returns nil, and adds the error to the supplied target, when the JSON is not valid, so that the schema is not
    # changed.
    def self.sanitize_schema(value, target)
      text = value.strip
      return text unless text.start_with?("{")

      JSON.parse(text)
    rescue JSON::ParserError => e
      target&.errors&.add(:properties, "Schema is not valid JSON: #{e.message}")
      nil
    end
  end
end
