ENV["RAILS_ENV"] ||= "test"

require "yaml"
require "amazing_print"
require "rails/version"
if Rails.version.to_f >= 5.2
  require_relative "../rjmc/config/environment"
  require "minitest/autorun"
  require "rails/test_help"
  require "minispec/rails"
else
  require_relative "../rjmc4/config/environment"
  require "minitest/autorun"
  require "rails/test_help"
  require "minitest/rails"
end

ActionController::TestCase
class ActionController::TestCase
  include RocketJobMissionControl::Engine.routes.url_helpers

  setup do
    @routes = RocketJobMissionControl::Engine.routes
  end
end
