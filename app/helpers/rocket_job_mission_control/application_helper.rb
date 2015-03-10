module RocketJobMissionControl
  module ApplicationHelper
    def site_title
      'Rocket Job Mission Control'
    end

    def title
      @page_title ||= params[:controller].to_s.titleize
      h(@full_title ? @full_title : [@page_title, site_title].compact.join(' | '))
    end

    def active_page(path)
      "active" if current_page?(path)
    end
  end
end
