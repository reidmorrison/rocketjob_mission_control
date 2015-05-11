module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require 'rocket_job'
    require 'jquery-rails'
    require 'haml'
    require 'mongo'
    require 'mongo_mapper'
    require 'mongo_ha'
    require 'bootstrap-sass'
    require 'sass-rails'
    require 'coffee-rails'
  end
end
