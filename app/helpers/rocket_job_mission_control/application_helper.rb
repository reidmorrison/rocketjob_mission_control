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
      stopping:  'fa-stop'
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

  end
end
