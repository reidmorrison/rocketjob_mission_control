module RocketJobMissionControl
  module ApplicationHelper
    STATE_ICON_MAP = {
      aborted:   'fa-stop',
      completed: 'fa-check',
      disabled:  'fa-stop',
      enabled:   'fa-check',
      failed:    'fa-exclamation-triangle',
      paused:    'fa-pause',
      pending:   'fa-inbox',
      queued:    'fa-inbox',
      running:   'fa-play',
      scheduled: 'fa-clock-o',
      starting:  'fa-cogs',
      stopping:  'fa-stop',
      zombie:    'fa-hourglass-o'
    }

    def state_icon(state)
      STATE_ICON_MAP[state.to_sym] + ' ' + state.to_s
    end

    def site_title
      'Rocket Job Mission Control'
    end

    def title
      @page_title ||= params[:controller].to_s.titleize
      h(@full_title || [@page_title, site_title].compact.join(' | '))
    end

    def active_page(path)
      'active' if current_page?(path)
    end

    def pretty_print_array_or_hash(arguments)
      return arguments unless arguments.kind_of?(Array) || arguments.kind_of?(Hash)
      json_string_options = {space: ' ', indent: '  ', array_nl: '<br />', object_nl: '<br />'}
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

    # Returns the editable field as html for use in editing dynamic fileds from a Job class.
    def editable_field_html(klass, property_name, value, f)
      field = klass.fields[property_name.to_s]
      return unless field && field.type
      placeholder = field.default_val

      case field.type.name
      when 'Symbol', 'String', 'Integer'
        options = extract_inclusion_values(klass, property_name)
        str     = "[#{field.type.name}]\n"
        if options
          str + f.select(property_name, options, {include_blank: options.include?(nil)}, {class: 'form-control'})
        else
          if field.type.name == 'Integer'
            str + f.number_field(property_name, value: value, class: 'form-control', placeholder: placeholder)
          else
            str + f.text_field(property_name, value: value, class: 'form-control', placeholder: placeholder)
          end
        end
      when 'Hash'
        "[JSON Hash]\n" +
          f.text_field(property_name, value: value ? value.to_json : '', class: 'form-control', placeholder: '{"key1":"value1", "key2":"value2", "key3":"value3"}')
      when 'Array'
        options = Array(value)
        "[Array]\n" +
          f.select(property_name, options_for_select(options, options), {include_hidden: false}, {class: 'selectize', multiple: true})
      when 'Mongoid::Boolean'
        name = "#{property_name}_true".to_sym
        str  = '<div class="radio-buttons">'
        str << f.label(name, 'true')
        str << f.radio_button(property_name, 'true', checked: value == 'true')
        str << f.label(name, 'false')
        str << f.radio_button(property_name, 'false', checked: value == 'false')
        str << f.label(name, 'none')
        str << f.radio_button(property_name, '', checked: value.blank?)
        str << '</div>'
      else
        "[#{field.type.name}]" +
          f.text_field(property_name, value: value, class: 'form-control', placeholder: placeholder)
      end
    end

  end
end
