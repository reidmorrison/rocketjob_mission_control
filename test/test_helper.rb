ENV['RAILS_ENV'] ||= 'test'
require_relative '../rjmc/config/environment'

require 'yaml'
require 'minitest/autorun'
require 'minitest/stub_any_instance'
require 'awesome_print'

require 'rails/test_help'
require 'minitest/rails'
require 'minitest/reporters'

# Include the complete backtrace?
Minitest.backtrace_filter = Minitest::BacktraceFilter.new if ENV['BACKTRACE'].present?

ActionController::TestCase
class ActionController::TestCase
  include RocketJobMissionControl::Engine.routes.url_helpers

  setup do
    @routes = RocketJobMissionControl::Engine.routes
  end
end
