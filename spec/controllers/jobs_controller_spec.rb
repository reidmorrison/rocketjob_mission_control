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
        expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :find], id: 42))
      end
    end
  end

  RSpec.describe JobsController do
    routes { Engine.routes }

    [:pause, :resume, :abort, :retry, :fail].each do |state|
      describe "PATCH ##{state}" do
        it_behaves_like "a jobs update controller" do
          let(:do_action) { patch state, id: 42, dirmon_entry: {id: 42, priority: 12} }
        end

        describe "with a valid job id" do
          let(:dirmon_entry) { spy(id: 42, to_param: 42) }

          before do
            allow(RocketJob::Job).to receive(:find).and_return(job)
            patch state, id: 42, dirmon_entry: {id: 42, priority: 12}
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

    describe "PATCH #update" do
      it_behaves_like "a jobs update controller" do
        let(:do_action) { patch :update, id: 42, dirmon_entry: {id: 42, priority: 12} }
      end

      describe "with a valid job id" do
        let(:dirmon_entry) { spy(id: 42, to_param: 42) }

        before do
          allow(RocketJob::Job).to receive(:find).and_return(job)
          patch :update, id: 42, dirmon_entry: {id: 42, priority: 12}
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
          expect(flash[:alert]).to eq(I18n.t(:failure, scope: [:dirmon_entry, :find], id: 42))
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
          expect(assigns(:dirmon_entry)).to be_present
        end

        it "assigns the jobs" do
          expect(assigns(:jobs)).to eq([])
        end

        it "grabs a sorted list of rocket jobs" do
          expect(result).to have_received(:sort).with(created_at: :desc)
        end
      end
    end

    describe "GET #running" do
      before do
        allow(RocketJob::Job).to receive(:where).and_return([])
        get :running
      end

      it { expect(response.status).to be(200) }

      it "queries for running jobs" do
        expect(RocketJob::Job).to have_received(:where).with(state: 'running')
      end

      it "returns expected jobs" do
        expect(assigns[:jobs]).to eq([])
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
        end

        describe "with no parameters" do
          before { get :index }

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

        describe "with a state filter" do
          before { get :index, states: states}

          context "that is empty" do
            let(:states) { [] }

            it { expect(response.status).to be(200) }

            it "grabs a sorted list of rocket jobs" do
              expect(result).to have_received(:sort).with(created_at: :desc)
            end

            it "returns the jobs" do
              expect(assigns(:jobs)).to match_array(jobs)
            end
          end

          context "with a state" do
            let(:query_spy) { spy(where: jobs) }
            let(:result) { spy(sort: query_spy) }
            let(:states) { ['completed', 'running'] }

            it { expect(response.status).to be(200) }

            it "grabs a filtered list of rocket jobs" do
              expect(query_spy).to have_received(:where).with(state: states)
            end

            it "returns the jobs" do
              expect(assigns(:jobs)).to match_array(jobs)
            end
          end
        end
      end
    end
  end
end
