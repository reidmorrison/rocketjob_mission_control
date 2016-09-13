module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require 'rocketjob'
    require 'jquery-rails'
    require 'yaml'
    require 'haml'
    require 'mongo'
    require 'mongo_mapper'
    require 'mongo_ha'
    require 'bootstrap-sass'
    require 'sass-rails'
    require 'coffee-rails'
    require 'kaminari'
    require 'jquery-datatables-rails'

    config.to_prepare do
      Rails.application.config.assets.precompile += %w(
        rocket_job_mission_control/rocket-icon-64x64.png
      )
    end
  end
end
