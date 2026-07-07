ENV["RAILS_ENV"] ||= "test"

require "simplecov"
SimpleCov.start "rails" do
  add_filter "/test/"
  add_filter "/rjmc/"
end

require "yaml"
require "rails/version"
require_relative "../rjmc/config/environment"
require "minitest/autorun"
require "rails/test_help"
require "minispec/rails"
require_relative "system_test_case"

module ActionController
  class TestCase
    include RocketJobMissionControl::Engine.routes.url_helpers

    setup do
      @routes = RocketJobMissionControl::Engine.routes
    end
  end
end
