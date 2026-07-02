require_relative "../../test_helper"

module RocketJobMissionControl
  class ActiveWorkersControllerTest < ActionController::TestCase
    describe ActiveWorkersController do
      before do
        set_role(:admin)
        RocketJob::Job.delete_all
        RocketJob::Server.delete_all
      end

      let :running_job do
        RocketJob::Jobs::SimpleJob.create!(state: :running, worker_name: "server1:1234:worker1", started_at: Time.now - 5)
      end

      let :other_running_job do
        RocketJob::Jobs::SimpleJob.create!(state: :running, worker_name: "server2:5678:worker1", started_at: Time.now - 5)
      end

      describe "GET #index" do
        describe "without a job_id" do
          before do
            running_job
            other_running_job
          end

          it "renders successfully" do
            get :index
            assert_response :success
            assert_nil assigns(:job)
          end

          it "returns the active workers for every running job" do
            get :index, format: :json
            assert_response :success
            data = JSON.parse(response.body)["data"]
            assert_equal 2, data.size
          end
        end

        describe "with a job_id" do
          before do
            running_job
            other_running_job
          end

          it "assigns the requested job" do
            get :index, params: {job_id: running_job.id}
            assert_response :success
            assert_equal running_job.id, assigns(:job).id
          end

          it "returns only the active workers for the requested job" do
            get :index, params: {job_id: running_job.id}, format: :json
            assert_response :success
            data = JSON.parse(response.body)["data"]
            assert_equal 1, data.size
            assert_includes data.first["0"], running_job.worker_name
          end
        end
      end
    end

    def set_role(r)
      Config.authorization_callback = lambda {
        {roles: [r]}
      }
    end
  end
end
