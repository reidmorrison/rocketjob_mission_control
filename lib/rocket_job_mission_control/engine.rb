module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require 'rocket_job'
    require 'haml'
    require 'mongo'
    require 'mongo_mapper'
    require 'mongo_ha'
  end
end
