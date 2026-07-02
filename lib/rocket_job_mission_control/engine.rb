module RocketJobMissionControl
  # The authorization callback
  module Config
    mattr_accessor :authorization_callback

    # The access policy class used to authorize actions.
    # Defaults to RocketJobMissionControl::AccessPolicy when not set.
    # May be a class, or a String/Symbol naming the class.
    mattr_accessor :access_policy_class
  end

  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require "rocketjob"
    require "access-granted"

    config.rocket_job_mission_control = ::RocketJobMissionControl::Config

    config.to_prepare do
      Rails.application.config.assets.precompile += %w[
        rocket_job_mission_control/rocket-icon-64x64.png
      ]
    end
  end
end
