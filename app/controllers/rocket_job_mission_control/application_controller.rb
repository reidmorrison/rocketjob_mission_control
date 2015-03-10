module RocketJobMissionControl
  class ApplicationController < ActionController::Base
    include ActionController::Live

    before_filter :find_job, only: [:download]

    def status
    end

    def scheduled
    end

    def overview
    end
  end
end
