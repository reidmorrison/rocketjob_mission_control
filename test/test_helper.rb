ENV['RAILS_ENV'] ||= 'test'
require_relative '../rjmc/config/environment'

require 'yaml'
require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'awesome_print'

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'

ActionController::TestCase
class ActionController::TestCase
  include RocketJobMissionControl::Engine.routes.url_helpers

  setup do
    @routes = RocketJobMissionControl::Engine.routes
  end
end
