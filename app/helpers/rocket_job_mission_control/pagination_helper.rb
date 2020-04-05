module RocketJobMissionControl
  module PaginationHelper
    def page_nav_disabled_class(current_position, boundary)
      current_position.to_i == boundary.to_i ? "disabled" : ""
    end
  end
end
