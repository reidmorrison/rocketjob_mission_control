require 'rails_helper'

module RocketJobMissionControl
  module Jobs
    RSpec.describe IndexFiltersController do
      routes { Engine.routes }

      states = %w(running paused completed aborted failed queued)

      states.each do |state|
        describe "GET ##{state}" do
          describe "with no #{state} jobs" do
            before do
              get state.to_sym
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it "returns no jobs" do
              expect(assigns(:jobs).count).to eq(0)
            end
          end

          describe "with #{state} jobs" do
            let!(:job) { RocketJob::Job.create(state: :scheduled) }
            let!(:state_job) { RocketJob::Job.create(state: state) }

            before do
              get state.to_sym
            end

            after do
              DatabaseCleaner.clean
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it "grabs a filtered list of rocket jobs" do
              expect(assigns(:jobs)).to match_array([state_job])
            end
          end
        end
      end

      describe "GET #scheduled" do
        describe "with no scheduled jobs" do
          before do
            get :scheduled
          end

          it "succeeds" do
            expect(response.status).to be(200)
          end

          it "returns no jobs" do
            expect(assigns(:jobs).count).to eq(0)
          end
        end

        describe "with scheduled jobs" do
          let!(:job) { RocketJob::Job.create(state: :queued) }
          let!(:scheduled_job) { RocketJob::Job.create(state: :queued, run_at: Date.tomorrow) }

          before do
            get :scheduled
          end

          after do
            DatabaseCleaner.clean
          end

          it "succeeds" do
            expect(response.status).to be(200)
          end

          it "grabs a filtered list of rocket jobs" do
            expect(assigns(:jobs)).to match_array([scheduled_job])
          end
        end
      end
    end
  end
end
