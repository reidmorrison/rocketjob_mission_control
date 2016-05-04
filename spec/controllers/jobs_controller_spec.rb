require 'rails_helper'

module RocketJobMissionControl
  RSpec.shared_examples "a jobs update controller" do
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

    [:pause, :resume, :abort, :retry, :fail].each do |state|
      describe "PATCH ##{state}" do
        it_behaves_like "a jobs update controller" do
          let(:do_action) { patch state, id: 42, job: {id: 42, priority: 12} }
        end

        describe "with a valid job id" do
          let(:job) { spy(id: 42, to_param: 42) }

          before do
            allow(RocketJob::Job).to receive(:find).and_return(job)
            patch state, id: 42, job: {id: 42, priority: 12}
          end

          it "redirects to the job" do
            expect(response).to redirect_to(job_path(42))
          end

          it "transitions the job" do
            expect(job).to have_received("#{state}!".to_sym)
          end
        end
      end
    end

    describe 'PATCH #run_now' do
      let(:scheduled_job) { spy(id: 12, run_at: 2.days.from_now) }

      before do
        allow(RocketJob::Job).to receive(:find).and_return(scheduled_job)
        patch :run_now, id: 12
      end

      it 'redirects to the scheduled_jobs_path' do
        expect(response).to redirect_to(scheduled_jobs_path)
      end

      it 'updates run_at' do
        expect(scheduled_job).to have_received(:update_attribute).with(:run_at, nil)
      end
    end


    describe "PATCH #update" do
      it_behaves_like "a jobs update controller" do
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
          expect(job).to have_received(:update_attributes).with('priority' => '12')
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
      end
    end

    describe "GET #index" do
      describe "with no jobs" do
        before do
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "returns no jobs" do
          expect(assigns(:jobs).count).to eq(0)
        end
      end

      describe "with jobs" do
        let(:jobs) { ['fake_job1', 'fake_job2'] }

        before do
          allow(RocketJob::Job).to receive(:sort).and_return(jobs)
          get :index
        end

        it "succeeds" do
          expect(response.status).to be(200)
        end

        it "grabs a sorted list of rocket jobs" do
          expect(RocketJob::Job).to have_received(:sort).with(_id: :desc)
        end

        it "returns the jobs" do
          expect(assigns(:jobs)).to eq(jobs)
        end
      end
    end
  end
end
