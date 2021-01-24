module RocketJobMissionControl
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    around_action :with_time_zone

    private

    def with_time_zone(&block)
      if time_zone = session["time_zone"] || "UTC"
        Time.use_zone(time_zone, &block)
      end
    end

    def current_policy
      @current_policy ||= begin
        @args =
          if Config.authorization_callback
            instance_exec(&Config.authorization_callback)
          else
            {roles: %i[admin]}
          end
        AccessPolicy.new(Authorization.new(**@args))
      end
    end

    def login
      @login ||= begin
        args = instance_exec(&Config.authorization_callback)
        args[:login]
      end
    end
  end
end
