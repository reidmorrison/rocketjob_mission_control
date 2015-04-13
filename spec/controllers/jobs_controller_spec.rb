require 'rails_helper'

module RocketJobMissionControl
  RSpec.shared_examples "a jobs show controller" do
    describe "with an invalid job id" do
      before do
        allow(RocketJob::Job).to receive(:find).and_return(nil)
        do_action
      end

      it "redirects" do
        expect(response).to redirect_to(jobs_path)
      end

      it "adds a flash alert message" do
        expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:job, :find], id: 42))
      end
    end
  end

  RSpec.describe JobsController do
    routes { Engine.routes }

    describe "PATCH #abort" do
      it_behaves_like "a jobs show controller" do
        let(:do_action) { patch :abort, id: 42, job: {id: 42, priority: 12} }
      end

      describe "with a valid job id" do
        let(:job) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Job).to receive(:find).and_return(job)
          patch :abort, id: 42, job: {id: 42, priority: 12}
        end

        it "redirects to the job" do
          expect(response).to redirect_to(job_path(42))
        end

        it "aborts the job" do
          expect(job).to have_received(:abort!)
        end
      end
    end

    describe "PATCH #update" do
      it_behaves_like "a jobs show controller" do
        let(:do_action) { patch :update, id: 42, job: {id: 42, priority: 12} }
      end

      describe "with a valid job id" do
        let(:job) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Job).to receive(:find).and_return(job)
          patch :update, id: 42, job: {id: 42, priority: 12}
        end

        it "redirects to the job" do
          expect(response).to redirect_to(job_path(42))
        end

        it "updates the job correctly" do
          expect(job).to have_received(:update_attributes!).with('priority' => '12')
        end
      end
    end

    describe "GET #show" do
      let(:result) { spy(sort: []) }

      before do
        allow(RocketJob::Job).to receive(:limit).and_return(result)
      end

      describe "with an invalid job id" do
        before do
          allow(RocketJob::Job).to receive(:find).and_return(nil)
          get :show, id: 42
        end

        it "redirects" do
          expect(response).to redirect_to(jobs_path)
        end

        it "adds a flash alert message" do
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:job, :find], id: 42))
        end
      end

      describe "with a valid job id" do
        before do
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

        it "grabs a sorted list of rocket jobs" do
          expect(result).to have_received(:sort).with(created_at: :desc)
        end
      end
    end

    describe "GET #index" do
      describe "with no jobs" do
        let(:result) { spy(sort: []) }

        before do
          allow(RocketJob::Job).to receive(:limit).and_return(result)
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "grabs a sorted list of rocket jobs" do
          expect(result).to have_received(:sort).with(created_at: :desc)
        end

        it "returns no jobs" do
          expect(assigns(:jobs)).to eq([])
        end
      end

      describe "with jobs" do
        let(:result) { spy(sort: jobs) }
        let(:jobs) { ['fake_job1', 'fake_job2'] }

        before do
          allow(RocketJob::Job).to receive(:limit).and_return(result)
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "grabs a sorted list of rocket jobs" do
          expect(result).to have_received(:sort).with(created_at: :desc)
        end

        it "returns the jobs" do
          expect(assigns(:jobs)).to match_array(jobs)
        end
      end
    end
  end
end
