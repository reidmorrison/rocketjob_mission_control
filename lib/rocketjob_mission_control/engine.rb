module RocketjobMissionControl
  # The authorization callback
  module Config
    mattr_accessor :authorization_callback
  end

  class Engine < ::Rails::Engine
    isolate_namespace RocketjobMissionControl

    require "rocketjob"
    require "jquery-rails"
    require "access-granted"
    begin
      require "rocketjob_enterprise"
    rescue LoadError
    end

    config.rocketjob_mission_control = ::RocketjobMissionControl::Config

    config.to_prepare do
      Rails.application.config.assets.precompile += %w[
        rocketjob_mission_control/rocket-icon-64x64.png
      ]
    end

    initializer 'webpacker.proxy' do |app|
      insert_middleware = RocketjobMissionControl.webpacker.config.dev_server.present? rescue nil
      next unless insert_middleware
      dev_server = Rails.version.to_i < 6 ? "Webpacker::DevServerProxy" : Webpacker::DevServerProxy

      app.middleware.insert_before(
        0, dev_server,
        ssl_verify_none: true,
        webpacker: RocketjobMissionControl.webpacker
      )

      app.middleware.insert_before(
        0, Rack::Static,
        urls: ["/rocketjob-mission-control-packs"], root: RocketjobMissionControl::Engine.root.join("public").to_s
      )
    end
  end
end
