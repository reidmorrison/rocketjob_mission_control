module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require 'rocketjob'
    require 'jquery-rails'
    require 'bootstrap-sass'
    require 'coffee-rails'
    require 'sass-rails'
    require 'haml'
    require 'jquery-datatables-rails'
    begin
      require 'rocketjob_pro'
    rescue LoadError
    end

    config.to_prepare do
      Rails.application.config.assets.precompile += %w(
        rocket_job_mission_control/rocket-icon-64x64.png
      )
    end
  end
end
