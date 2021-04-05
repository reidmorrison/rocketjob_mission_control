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
    def extract_inclusion_values(klass, attribute, include_nil_option)
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
    #   include_nil_option:
    #     Is used by dirmon entries where a nil value just means no value selected.
    #     Prevents filling default values in for all fields in the dirmon entry
    def editable_field_html(klass, field_name, value, f, include_nil_option = false)
      # When editing a job the values are of the correct type.
      # When editing a dirmon entry values are strings.
      field = klass.fields[field_name.to_s]
      return unless field&.type

      placeholder = field.default_val
      placeholder = nil if placeholder.is_a?(Proc)

      case field.type.name
      when "Integer"
        options = extract_inclusion_values(klass, field_name, include_nil_option)
        f.number_field(field_name, in: options, include_blank: include_nil_option, value: value, class: "form-control", placeholder: placeholder)
      when "String", "Symbol", "Mongoid::StringifiedSymbol"
        options = extract_inclusion_values(klass, field_name, include_nil_option)
        if options
          f.select(field_name, options, {include_blank: options.include?(nil), selected: value}, {class: "selectize form-control"})
        else
          f.text_field(field_name, value: value, class: "form-control", placeholder: placeholder)
        end
      when "Boolean", "Mongoid::Boolean"
        options = extract_inclusion_values(klass, field_name, include_nil_option) || [nil, "true", "false"]
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
  end
end
