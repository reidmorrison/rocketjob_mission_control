module RocketJobMissionControl
  module ApplicationHelper
    STATE_ICON_MAP = {
      aborted:   "fa-solid fa-ban",
      completed: "fa-solid fa-circle-check",
      disabled:  "fa-solid fa-ban",
      enabled:   "fa-solid fa-circle-check",
      failed:    "fa-solid fa-triangle-exclamation",
      paused:    "fa-solid fa-pause",
      pending:   "fa-solid fa-cogs",
      queued:    "fa-solid fa-inbox",
      running:   "fa-solid fa-person-running",
      sleeping:  "fa-solid fa-hourglass",
      scheduled: "fa-solid fa-clock",
      starting:  "fa-solid fa-cogs",
      stopping:  "fa-solid fa-stop",
      zombie:    "fa-solid fa-ghost"
    }.freeze

    # The encodings to suggest for the text in a file, such as that of a category's files. Any other encoding that
    # Ruby knows can be typed in, and the model validates it, see RocketJob::EncodingValidator.
    SUGGESTED_ENCODINGS = %w[UTF-8 Windows-1252 ISO-8859-1 ISO-8859-15 US-ASCII UTF-16LE UTF-16BE Shift_JIS IBM037].freeze

    def state_icon(state)
      "#{STATE_ICON_MAP[state.to_sym]} #{state}"
    end

    # Whether a known status icon exists for the given state (e.g. "completed").
    # Used to decide whether to show a status icon next to a page title.
    def state?(state)
      STATE_ICON_MAP.key?(state.to_s.downcase.to_sym)
    end

    def site_title
      "Rocket Job Mission Control"
    end

    def title
      @page_title ||= params[:controller].to_s.titleize
      h(@full_title || [@page_title, site_title].compact.join(" | "))
    end

    # Highlights a top-nav item for every page in that section by matching the
    # current controller, e.g. "Jobs" stays active across running/failed/etc.
    def active_page(*controllers)
      "active" if controllers.map(&:to_s).include?(controller_name)
    end

    def pretty_print_array_or_hash(arguments)
      return arguments unless arguments.is_a?(Array) || arguments.is_a?(Hash)

      json_string_options = {space: " ", indent: "  ", array_nl: "<br />", object_nl: "<br />"}
      JSON.generate(arguments, json_string_options).html_safe
    end

    # Arrays/Hashes with more than this many top-level entries are collapsed by
    # default when rendered as a JSON tree.
    JSON_TREE_COLLAPSE_THRESHOLD = 10

    # Render an Array or Hash as an interactive, collapsible JSON tree
    # (see jquery.json-viewer.js / json_tree_init.js). Collections with more than
    # JSON_TREE_COLLAPSE_THRESHOLD top-level entries start collapsed. The value is
    # embedded as JSON for the viewer, with a <noscript> plain-text fallback for
    # when JavaScript is unavailable.
    def render_json_tree(value)
      plain     = JSON.parse(value.to_json)
      collapsed = plain.respond_to?(:size) && plain.size > JSON_TREE_COLLAPSE_THRESHOLD

      content_tag(:div, class: "json-tree", data: {collapsed: collapsed}) do
        content_tag(:script, raw(ERB::Util.json_escape(JSON.generate(plain))), type: "application/json") +
          content_tag(:noscript, content_tag(:pre, JSON.pretty_generate(plain)))
      end
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

    # Whether the attribute holds the encoding of the text in a file, which the class declares by validating it as one,
    # such as RocketJob::Category::Base#encoding or RocketJob::Jobs::CopyFileJob#source_encoding.
    def encoding_field?(klass, attribute)
      klass.validators_on(attribute).any?(RocketJob::EncodingValidator)
    end

    # Returns the select for the encoding of the text in a file, which suggests the common encodings, and takes any
    # other that is typed in, see tom_select_init.js. Blank is UTF-8, or the format's own encoding.
    def encoding_select(f, attribute, value)
      options = value.blank? || SUGGESTED_ENCODINGS.include?(value) ? SUGGESTED_ENCODINGS : [value, *SUGGESTED_ENCODINGS]
      f.select(attribute, options, {include_blank: true, selected: value}, {class: "tom-select form-select"})
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
        f.number_field(field_name, in: options, include_blank: false, value: value, class: "form-control",
placeholder: placeholder)
      when "String", "Symbol", "Mongoid::StringifiedSymbol"
        options = extract_inclusion_values(klass, field_name)
        if encoding_field?(klass, field_name)
          encoding_select(f, field_name, value)
        elsif options
          f.select(field_name, options, {include_blank: options.include?(nil), selected: value},
                   {class: "tom-select form-select"})
        else
          f.text_area(field_name, value: value || "", class: "form-control", placeholder: placeholder)
        end
      when "Boolean", "Mongoid::Boolean"
        options = extract_inclusion_values(klass, field_name) || [nil, "true", "false"]
        f.select(field_name, options, {include_blank: options.include?(nil), selected: value},
                 {class: "tom-select form-select"})
      when "Hash"
        "[JSON Hash]\n".html_safe +
          f.text_field(field_name, value: value ? value.to_json : "", class: "form-control",
placeholder: '{"key1":"value1", "key2":"value2", "key3":"value3"}')
      when "Array"
        options = value.present? ? Array(value) : []
        f.select(field_name, options_for_select(options, options), {include_hidden: true},
                 {class: "tom-select form-select", multiple: true})
      else
        "[#{field.type.name}]".html_safe +
          f.text_field(field_name, value: value, class: "form-control", placeholder: placeholder)
      end
    end
  end
end
