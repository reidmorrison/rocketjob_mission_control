require_relative "../../test_helper"

module RocketJobMissionControl
  class TestController < ApplicationController
    def index
      @time_zone = Time.zone

      render plain: "Time Zoned"
    end
  end

  class ApplicationControllerTest < ActionController::TestCase
    describe TestController do
      describe "#with_time_zone" do
        it "uses correct timezone with session and time_zone set" do
          if Rails.version.to_i >= 5
            session["time_zone"] = "America/Los_Angeles"
            get :index
          else
            get :index, {}, {"time_zone" => "America/Los_Angeles"}
          end
          assert_equal "America/Los_Angeles", assigns(:time_zone).name
        end

        it "uses correct timezone with session, but no time_zone set" do
          if Rails.version.to_i >= 5
            session["user_id"] = "42"
            get :index
          else
            get :index, {}, {"user_id" => "42"}
          end
          assert_equal "UTC", assigns(:time_zone).name
        end

        it "uses correct timezone without a session" do
          get :index
          assert_equal "UTC", assigns(:time_zone).name
        end
      end
    end
  end
end
