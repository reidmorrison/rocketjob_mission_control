ENV["RAILS_ENV"] ||= "test"

require "yaml"
require "amazing_print"
require "rails/version"
require_relative "../rjmc/config/environment"
require "minitest/autorun"
require "rails/test_help"
require "minispec/rails"

ActionController::TestCase

class ActionController::TestCase
  include RocketJobMissionControl::Engine.routes.url_helpers

  setup do
    @routes = RocketJobMissionControl::Engine.routes
  end
end

class ActionDispatch::IntegrationTest
  include TurboAssertionsHelper
end
