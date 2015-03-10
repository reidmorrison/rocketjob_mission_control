require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe JobsController do
    routes { Engine.routes }

    describe "GET #show" do
      describe "with a valid job" do
        before do
          allow(RocketJob::Job).to receive(:sort).and_return([])
          allow(RocketJob::Job).to receive(:find).and_return('job')
          get :show, id: 42
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "assigns the job" do
          expect(assigns(:job)).to be_present
        end

        it "assigns the jobs" do
          expect(assigns(:jobs)).to eq([])
        end
      end
    end

    describe "GET #index" do
      describe "with no jobs" do
        before do
          allow(RocketJob::Job).to receive(:sort).and_return([])
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end
        it "returns no jobs" do
          expect(assigns(:jobs)).to eq([])
        end
      end

      describe "with jobs" do
        let(:jobs) { ['fake_job1', 'fake_job2'] }

        before do
          allow(RocketJob::Job).to receive(:sort).and_return(jobs)
          get :index, use_route: 'jobs'
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end
        it "returns the jobs" do
          expect(assigns(:jobs)).to match_array(jobs)
        end
      end
    end
  end
end
