require 'test_helper'

module RocketJobMissionControl
  class JobsControllerTest < ActionController::TestCase
    describe JobsController do
      before do
        @routes = Engine.routes
        @controller.stubs(:render)
      end

      describe "GET #show" do
        describe "with a valid job" do
          before do
            RocketJob::Job.stubs(:sort).returns([])
            RocketJob::Job.stubs(:find).returns('job')
            get :show, id: 42
          end

          it "succeeds" do
            assert_response(200)
          end

          it "assigns the job" do
            assert_not_nil(assigns(:job))
          end

          it "assigns the jobs" do
            assert_not_nil(assigns(:jobs))
          end
        end
      end

      describe "GET #index" do
        describe "with no jobs" do
          before do
            RocketJob::Job.stubs(:sort).returns([])
            get :index
          end

          it "succeeds" do
            assert_response(200)
          end
          it "returns no jobs" do
            assert_equal([], assigns(:jobs))
          end
        end

        describe "with jobs" do
          before do
            RocketJob::Job.stub(:sort, ['fake_job1', 'fake_job2']) do
              get :index, use_route: 'jobs'
            end
          end

          it "succeeds" do
            assert_response(200)
          end
          it "returns the jobs" do
            assert_equal(['fake_job1', 'fake_job2'], assigns(:jobs))
          end
        end
      end
    end
  end
end
