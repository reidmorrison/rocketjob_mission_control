require "rocketjob_mission_control/engine"

module RocketjobMissionControl
  class << self
    def webpacker
      @webpacker ||= ::Webpacker::Instance.new(
        root_path: RocketjobMissionControl::Engine.root,
        config_path: RocketjobMissionControl::Engine.root.join("config", "webpacker.yml")
      )
    end
  end
end
