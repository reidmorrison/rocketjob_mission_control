module RocketJobMissionControl
  module ApplicationHelper
    STATE_ICON_MAP = {
      aborted:   "fas fa-stop",
      completed: "fas fa-check",
      disabled:  "fas fa-stop",
      enabled:   "fas fa-check",
      failed:    "fas fa-exclamation-triangle",
      paused:    "fas fa-pause",
      pending:   "fas fa-inbox",
      queued:    "fas fa-inbox",
      running:   "fas fa-play",
      sleeping:  "fas fa-hourglass",
      scheduled: "fas fa-clock",
      starting:  "fas fa-cogs",
      stopping:  "fas fa-stop",
      zombie:    "fas fa-hourglass"
    }.freeze

    def state_icon(state)
      STATE_ICON_MAP[state.to_sym] + " " + state.to_s
    end

    def site_title
      "Rocket Job Mission Control"
    end

    def title
      @page_title ||= params[:controller].to_s.titleize
      h(@full_title || [@page_title, site_title].compact.join(" | "))
    end

    def active_page(path)
      "active" if current_page?(path)
    end

    def pretty_print_array_or_hash(arguments)
      return arguments unless arguments.is_a?(Array) || arguments.is_a?(Hash)

      json_string_options = {space: " ", indent: "  ", array_nl: "<br />", object_nl: "<br />"}
      JSON.generate(arguments, json_string_options).html_safe
    end

    # Returns [Array] list of inclusion values for this attribute.
    # Returns nil when there are no inclusion values for this attribute.
    def extract_inclusion_values(klass, attribute)
      values = nil

      klass.validators_on(attribute).each do |validator|
        case validator
        when ActiveModel::Validations::InclusionValidator
          values = validator.options[:in]
        end
      end

      values
    end

    # Returns the editable field as html for use in editing dynamic fields from a Job class.
    def editable_field_html(klass, field_name, value, f)
      # When editing a job the values are of the correct type.
      # When editing a dirmon entry values are strings.
      field = klass.fields[field_name.to_s]
      return unless field&.type

      placeholder = field.default_val
      placeholder = nil if placeholder.is_a?(Proc)

      case field.type.name
      when "Integer"
        options = extract_inclusion_values(klass, field_name)
        f.number_field(field_name, in: options, include_blank: false, value: value, class: "form-control", placeholder: placeholder)
      when "String", "Symbol", "Mongoid::StringifiedSymbol"
        options = extract_inclusion_values(klass, field_name)
        if options
          f.select(field_name, options, {include_blank: options.include?(nil), selected: value}, {class: "selectize form-control"})
        else
          f.text_field(field_name, value: value, class: "form-control", placeholder: placeholder)
        end
      when "Boolean", "Mongoid::Boolean"
        options = extract_inclusion_values(klass, field_name) || [nil, "true", "false"]
        f.select(field_name, options, {include_blank: options.include?(nil), selected: value}, {class: "selectize form-control"})
      when "Hash"
        "[JSON Hash]\n".html_safe +
          f.text_field(field_name, value: value ? value.to_json : "", class: "form-control", placeholder: '{"key1":"value1", "key2":"value2", "key3":"value3"}')
      when "Array"
        options = Array(value)
        f.select(field_name, options_for_select(options, options), {include_hidden: false}, {class: "selectize form-control", multiple: true})
      else
        "[#{field.type.name}]".html_safe +
          f.text_field(field_name, value: value, class: "form-control", placeholder: placeholder)
      end
    end

    # This method creates a link with `data-id` `data-fields` attributes. These attributes are used to create new instances of the nested fields through Javascript.
    def link_to_add_fields(name, f, association, option)
      # Takes an object (@job) and creates a new instance of its associated model (:properties)
      new_object = f.object.send(association).klass.new

      # Saves the unique ID of the object into a variable.
      # This is needed to ensure the key of the associated array is unique. This is makes parsing the content in the `data-fields` attribute easier through Javascript.
      # We could use another method to achive this.
      id = new_object.object_id

      # https://api.rubyonrails.org/ fields_for(record_name, record_object = nil, fields_options = {}, &block)
      # record_name = :addresses
      # record_object = new_object
      # fields_options = { child_index: id }
      # child_index` is used to ensure the key of the associated array is unique, and that it matched the value in the `data-id` attribute.
      # `person[addresses_attributes][child_index_value][_destroy]`
      fields = f.fields_for(association, new_object, child_index: id) do |builder|
        # `association.to_s.singularize + "_fields"` ends up evaluating to `address_fields`
        # The render function will then look for `views/people/_address_fields.html.erb`
        # The render function also needs to be passed the value of 'builder', because `views/dirmon_entries/_input_categories.html.erb` needs this to render the form tags.
        render(association.to_s.singularize + "_fields", f: builder)
      end

      # This renders a simple link, but passes information into `data` attributes.
      # This info can be named anything we want, but in this case we chose `data-id:` and `data-fields:`.
      # The `id:` is from `new_object.object_id`.
      # The `fields:` are rendered from the `fields` blocks.
      # We use `gsub("\n", "")` to remove anywhite space from the rendered partial.
      # The `id:` value needs to match the value used in `child_index: id`.
      link_to(name, '#', class: "add_fields btn btn-#{option}", data: { id: id, fields: fields.gsub("\n", "") })
    end
  end
end
