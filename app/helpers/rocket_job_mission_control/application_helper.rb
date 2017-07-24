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
      sleeping:  'fa-hourglass-o',
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

    # Returns the editable field as html for use in editing dynamic fields from a Job class.
    def editable_field_html(klass, field_name, value, f, include_nil_selectors = false)
      # When editing a job the values are of the correct type.
      # When editing a dirmon entry values are strings.
      field = klass.fields[field_name.to_s]
      return unless field && field.type

      placeholder = field.default_val
      placeholder = nil if placeholder.is_a?(Proc)

      case field.type.name
      when 'Symbol', 'String', 'Integer'
        options = extract_inclusion_values(klass, field_name)
        str     = "[#{field.type.name}]\n".html_safe
        if options
          str + f.select(field_name, options, {include_blank: options.include?(nil) || include_nil_selectors, selected: value}, {class: 'form-control'})
        else
          if field.type.name == 'Integer'
            str + f.number_field(field_name, value: value, class: 'form-control', placeholder: placeholder)
          else
            str + f.text_field(field_name, value: value, class: 'form-control', placeholder: placeholder)
          end
        end
      when 'Hash'
        "[JSON Hash]\n".html_safe +
          f.text_field(field_name, value: value ? value.to_json : '', class: 'form-control', placeholder: '{"key1":"value1", "key2":"value2", "key3":"value3"}')
      when 'Array'
        options = Array(value)
        "[Array]\n".html_safe +
          f.select(field_name, options_for_select(options, options), {include_hidden: false}, {class: 'selectize', multiple: true})
      when 'Mongoid::Boolean'
        name = "#{field_name}_true".to_sym
        value = value.to_s
        str  = '<div class="radio-buttons">'.html_safe
        str << f.radio_button(field_name, 'true', checked: value == 'true')
        str << ' '.html_safe + f.label(name, 'true')
        str << ' '.html_safe + f.radio_button(field_name, 'false', checked: value == 'false')
        str << ' '.html_safe + f.label(name, 'false')
        # Allow this field to be unset (nil).
        if include_nil_selectors
          str << ' '.html_safe + f.radio_button(field_name, '', checked: value == '')
          str << ' '.html_safe + f.label(name, 'nil')
        end

        str << '</div>'.html_safe
      else
        "[#{field.type.name}]".html_safe +
          f.text_field(field_name, value: value, class: 'form-control', placeholder: placeholder)
      end
    end

  end
end
