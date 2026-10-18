module RocketJobMissionControl
  class ApplicationController < ActionController::Base
    protect_from_forgery with: :exception

    # The status of a form that is rendered again to show why it could not be saved. Turbo Drive ignores a form
    # response that renders with 200, so the errors would never be shown. Rack 2.2, which Rails 7.2 allows, does not
    # know the name :unprocessable_content, and Rack 3.1 deprecates :unprocessable_entity.
    FORM_ERROR_STATUS = 422

    around_action :with_time_zone

    private

    def with_time_zone(&)
      return unless (time_zone = session["time_zone"] || "UTC")

      Time.use_zone(time_zone, &)
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
