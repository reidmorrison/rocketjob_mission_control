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
        access_policy_class.new(Authorization.new(**@args))
      end
    end

    def access_policy_class
      policy = Config.access_policy_class || RocketJobMissionControl::AccessPolicy
      policy.is_a?(Class) ? policy : policy.to_s.constantize
    end

    def login
      return unless Config.authorization_callback

      @login ||= begin
        args = instance_exec(&Config.authorization_callback)
        args[:login]
      end
    end
  end
end
