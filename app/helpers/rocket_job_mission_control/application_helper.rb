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
        if options
          f.select(field_name, options, {include_blank: options.include?(nil), selected: value},
                   {class: "selectize form-select"})
        else
          f.text_area(field_name, value: value || "", class: "form-control", placeholder: placeholder)
        end
      when "Boolean", "Mongoid::Boolean"
        options = extract_inclusion_values(klass, field_name) || [nil, "true", "false"]
        f.select(field_name, options, {include_blank: options.include?(nil), selected: value},
                 {class: "selectize form-select"})
      when "Hash"
        "[JSON Hash]\n".html_safe +
          f.text_field(field_name, value: value ? value.to_json : "", class: "form-control",
placeholder: '{"key1":"value1", "key2":"value2", "key3":"value3"}')
      when "Array"
        options = value.present? ? Array(value) : []
        f.select(field_name, options_for_select(options, options), {include_hidden: true},
                 {class: "selectize form-select", multiple: true})
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
        render("#{association.to_s.singularize}_fields", f: builder)
      end

      # This renders a simple link, but passes information into `data` attributes.
      # This info can be named anything we want, but in this case we chose `data-id:` and `data-fields:`.
      # The `id:` is from `new_object.object_id`.
      # The `fields:` are rendered from the `fields` blocks.
      # We use `gsub("\n", "")` to remove anywhite space from the rendered partial.
      # The `id:` value needs to match the value used in `child_index: id`.
      link_to(name, "#", class: "add_fields btn btn-#{option}", data: {id: id, fields: fields.delete("\n")})
    end
  end
end
