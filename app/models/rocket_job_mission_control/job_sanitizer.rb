module RocketJobMissionControl
  module JobSanitizer

    # Returns [Hash] the permissible params for the specified job class, after sanitizing.
    def self.sanitize(properties, job_class, target, nil_blank = true)
      permissible_params = {}
      job_class.user_editable_fields.each do |field_name|
        if value = properties[field_name]
          field = job_class.fields[field_name.to_s]
          next unless field && field.type

          case field.type.name
          when 'Hash'
            begin
              permissible_params[field_name] = JSON.parse(value)
            rescue JSON::ParserError => e
              target.errors.add(:properties, e.message)
            end
          else
            if value.blank?
              permissible_params[field_name] = nil if nil_blank
            else
              permissible_params[field_name] = value
            end
          end

        end
      end
      permissible_params
    end

  end
end
