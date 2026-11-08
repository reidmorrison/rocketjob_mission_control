module RocketJobMissionControl
  module DirmonSanitizer
    DIRMON_FIELDS = %i[archive_directory job_class_name name pattern].freeze

    def self.sanitize(params, job_class, target)
      permissible_params = {}

      DIRMON_FIELDS.each do |field_name|
        value = params[field_name]
        next if value.blank?

        permissible_params[field_name] = value
      end

      if params.key?(:properties)
        properties                      = sanitize_properties(params[:properties], job_class, target)
        permissible_params[:properties] = properties if properties.present?
      end

      permissible_params
    end

    # Returns [Hash] the supplied properties that a form posted, sanitized for a Dirmon entry, see JobSanitizer.sanitize,
    # without those posted blank, which .update_properties removes from the entry.
    def self.sanitize_properties(posted, job_class, target)
      JobSanitizer.sanitize(posted, job_class, target, false)
    end

    # Returns [Hash] the properties of the supplied Dirmon entry with the changes that its form posted, see
    # .diff_properties: each property that the form posted is set when it differs from the job class's default, and
    # removed otherwise, so that the job class decides it. Every other property is kept as it is saved, such as an
    # input category's `allowed_columns` or `file_name`, since the form does not show it.
    #
    # Parameters
    #   posted [Hash]
    #     The properties that the form posted, see JobSanitizer.posted_fields and .posted_categories.
    #
    #   sanitized [Hash]
    #     The same properties after .sanitize_properties.
    #
    #   dirmon_entry [RocketJob::DirmonEntry]
    #     The entry whose properties the form shows, such as the one being edited or copied.
    def self.update_properties(posted, sanitized, dirmon_entry)
      properties = dirmon_entry.properties.to_h.deep_stringify_keys
      return properties if posted.blank?

      changes = diff_properties(sanitized, dirmon_entry).deep_stringify_keys
      JobSanitizer.posted_fields(posted, dirmon_entry.job_class).each do |name|
        merge_property(properties, changes, name.to_s)
      end
      JobSanitizer.posted_categories(posted).each do |category|
        merge_category(properties, category, changes, dirmon_entry.job_class)
      end
      properties
    end

    # Returns [Hash] the difference between the supplied params and those already set in the job itself
    def self.diff_properties(sanitized_properties, dirmon_entry)
      default_job = dirmon_entry.job_class.new
      # Without properties to change, such as when only the pattern changed, the job has the defaults.
      updated_job = dirmon_entry.job_class.from_properties(sanitized_properties || {})
      properties  = {}
      sanitized_properties&.each_pair do |name, value|
        if name == :input_categories
          categories = []
          value.each do |category_properties|
            category_name = category_properties[:name].to_sym
            props         = diff_category(category_properties, updated_job.input_category(category_name),
                                          default_job.input_category(category_name))
            categories << props unless props.empty?
          end
          properties[:input_categories] = categories unless categories.empty?
        elsif name == :output_categories
          categories = []
          value.each do |category_properties|
            category_name = category_properties[:name].to_sym
            props         = diff_category(category_properties, updated_job.output_category(category_name),
                                          default_job.output_category(category_name))
            categories << props unless props.empty?
          end
          properties[:output_categories] = categories unless categories.empty?
        elsif default_job.public_send(name) != updated_job.public_send(name)
          properties[name] = value
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

    # Merges the changes that the form posted for the supplied category, see JobSanitizer.posted_categories, into the
    # supplied properties, see .update_properties. A saved category is found by its name, or is main without one, as a
    # job reads it, and is removed when it is left with only its name, since a job then has the job class's category.
    #
    # A category with a schema cannot have the options that the schema replaces, such as an input category's
    # `allowed_columns`, see RocketJob::Category::Input.deprecated_column_options. Those that the form does not show are
    # removed, since they could not be changed otherwise, so that giving a category a schema replaces them.
    def self.merge_category(properties, posted, changes, job_class)
      key        = posted.property.to_s
      categories = Array(properties[key]).dup
      change     = Array(changes[key]).find { |category| category["name"].to_s == posted.name } || {}
      index      = categories.index { |category| category.is_a?(Hash) && (category["name"] || "main").to_s == posted.name }
      category   = index ? categories[index].dup : {"name" => posted.name}

      fields = posted.fields.map(&:to_s)
      fields.each { |field| merge_property(category, change, field) }
      remove_options_replaced_by_schema(category, posted, job_class)

      if (category.keys - ["name"]).empty?
        categories.delete_at(index) if index
      elsif index
        categories[index] = category
      else
        categories << category
      end
      categories.empty? ? properties.delete(key) : properties[key] = categories
    end

    # Removes the options that the schema of the supplied category replaces, see .merge_category: its own schema, or else
    # the one that its job class gives it. Those that the form posted stay, such as an input category's `skip_unknown`,
    # since it can change them.
    def self.remove_options_replaced_by_schema(category, posted, job_class)
      schema = category["schema"].presence || job_class_category(job_class, posted)&.schema
      return if schema.blank?

      replaced = posted.category_class.deprecated_column_options(category.merge("schema" => schema))
      category.except!(*(replaced - posted.fields.map(&:to_s)))
    end

    # Returns [RocketJob::Category::Input|RocketJob::Category::Output] the category of a new job of the supplied class
    # that the supplied posted category changes, see JobSanitizer.posted_categories, or nil when it has none.
    def self.job_class_category(job_class, posted)
      job_class.new.public_send(posted.property).find { |category| category.name.to_s == posted.name }
    end

    # Sets the supplied property to its change, or removes it when the form did not change it from the default.
    def self.merge_property(properties, changes, key)
      if changes.key?(key)
        properties[key] = changes[key]
      else
        properties.delete(key)
      end
    end

    private_class_method :merge_category, :remove_options_replaced_by_schema, :job_class_category, :merge_property
  end
end
