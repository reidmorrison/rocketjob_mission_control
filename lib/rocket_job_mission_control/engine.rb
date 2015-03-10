module RocketJobMissionControl
  class Engine < ::Rails::Engine
    isolate_namespace RocketJobMissionControl

    require 'rocket_job'
  end
end
