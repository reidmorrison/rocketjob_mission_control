module RocketJobMissionControl
  module DirmonSanitizer
    DIRMON_FIELDS = %i[archive_directory job_class_name name pattern].freeze

    # The params that the form posts each kind of category of a Dirmon entry's properties in.
    CATEGORY_PARAMS = {
      "input_categories"  => :input_categories_attributes,
      "output_categories" => :output_categories_attributes
    }.freeze

    def self.sanitize(params, job_class, target)
      permissible_params = {}

      DIRMON_FIELDS.each do |field_name|
        value = params[field_name]
        next if value.blank?

        permissible_params[field_name] = value
      end

      if params.key?(:properties)
        properties                      = JobSanitizer.sanitize(params[:properties], job_class, target, false)
        permissible_params[:properties] = properties if properties.present?
      end

      permissible_params
    end

    # Returns [Hash] the properties of the supplied Dirmon entry with the changes that its form posted, see
    # .diff_properties: each property that the form posted is set when it differs from the job class's default, and
    # removed otherwise, so that the job class decides it. Every other property is kept as it is saved, such as an
    # input category's `allowed_columns` or `file_name`, since the form does not show it.
    #
    # Parameters
    #   posted [Hash]
    #     The properties that the form posted.
    #
    #   sanitized [Hash]
    #     The same properties after .sanitize.
    #
    #   dirmon_entry [RocketJob::DirmonEntry]
    #     The entry being edited.
    def self.update_properties(posted, sanitized, dirmon_entry)
      properties = dirmon_entry.properties.to_h.deep_stringify_keys
      return properties if posted.blank?

      changes = diff_properties(sanitized, dirmon_entry).deep_stringify_keys
      dirmon_entry.job_class.user_editable_fields.each do |name|
        merge_property(properties, changes, name.to_s) if posted.key?(name)
      end

      CATEGORY_PARAMS.each_pair do |key, attributes|
        next unless posted.key?(attributes)

        categories = merge_categories(Array(properties[key]), posted[attributes], Array(changes[key]))
        categories.empty? ? properties.delete(key) : properties[key] = categories
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

    # Returns [Array<Hash>] the supplied saved categories with the changes that the form posted for each, see
    # .update_properties. A saved category is found by its name, or is main without one, as a job reads it. A category
    # left with only its name is removed, since a job then has the job class's category.
    def self.merge_categories(categories, posted, changes)
      categories = categories.dup
      posted.each_pair do |_, category_params|
        name     = (category_params[:name].presence || "main").to_s
        change   = changes.find { |category| category["name"].to_s == name } || {}
        index    = categories.index { |category| category.is_a?(Hash) && (category["name"] || "main").to_s == name }
        category = index ? categories[index].dup : {"name" => name}

        (JobSanitizer::CATEGORIES_FIELDS - %i[id name]).each do |field|
          merge_property(category, change, field.to_s) if category_params.key?(field)
        end

        if (category.keys - ["name"]).empty?
          categories.delete_at(index) if index
        elsif index
          categories[index] = category
        else
          categories << category
        end
      end
      categories
    end

    # Sets the supplied property to its change, or removes it when the form did not change it from the default.
    def self.merge_property(properties, changes, key)
      if changes.key?(key)
        properties[key] = changes[key]
      else
        properties.delete(key)
      end
    end

    private_class_method :merge_categories, :merge_property
  end
end
