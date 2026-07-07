require "capybara/cuprite"

Capybara.default_max_wait_time = 5

module RocketJobMissionControl
  class SystemTestCase < ActionDispatch::SystemTestCase
    include Engine.routes.url_helpers

    driven_by :cuprite, screen_size: [1200, 800], options: {
      process_timeout: 20,
      timeout:         10,
      browser_options: ENV["CI"] ? {"no-sandbox" => nil} : {}
    }

    setup do
      Config.authorization_callback = -> { {roles: [:admin]} }
    end
  end
end
