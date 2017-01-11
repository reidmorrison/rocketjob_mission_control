module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    config.to_prepare do
      Rails.application.config.assets.precompile += %w(
        rocket_job_mission_control/rocket-icon-64x64.png
      )
    end
  end
end
