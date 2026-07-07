require_relative "../../test_helper"

module RocketJobMissionControl
  class TestController < ApplicationController
    def index
      @time_zone = Time.zone

      render plain: "Time Zoned"
    end
  end

  class CustomAccessPolicy < AccessPolicy
  end

  class ApplicationControllerTest < ActionController::TestCase
    tests TestController

    describe TestController do
      describe "#access_policy_class" do
        before do
          @original_policy_class = Config.access_policy_class
          @original_callback     = Config.authorization_callback
          Config.authorization_callback = nil
        end

        after do
          Config.access_policy_class    = @original_policy_class
          Config.authorization_callback = @original_callback
        end

        it "defaults to AccessPolicy when not configured" do
          Config.access_policy_class = nil

          assert_equal AccessPolicy, @controller.send(:access_policy_class)
          assert_instance_of AccessPolicy, @controller.send(:current_policy)
        end

        it "uses a configured policy class" do
          Config.access_policy_class = CustomAccessPolicy

          assert_equal CustomAccessPolicy, @controller.send(:access_policy_class)
          assert_instance_of CustomAccessPolicy, @controller.send(:current_policy)
        end

        it "constantizes a policy class supplied as a String" do
          Config.access_policy_class = "RocketJobMissionControl::CustomAccessPolicy"

          assert_equal CustomAccessPolicy, @controller.send(:access_policy_class)
          assert_instance_of CustomAccessPolicy, @controller.send(:current_policy)
        end
      end

      describe "#with_time_zone" do
        before do
          @routes = ActionDispatch::Routing::RouteSet.new
          @routes.draw { get "index" => "rocket_job_mission_control/test#index" }
        end

        it "uses correct timezone with session and time_zone set" do
          session["time_zone"] = "America/Los_Angeles"
          get :index

          assert_equal "America/Los_Angeles", assigns(:time_zone).name
        end

        it "uses correct timezone with session, but no time_zone set" do
          session["user_id"] = "42"
          get :index

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
