require 'rails_helper'

module RocketJobMissionControl
  module Jobs
    RSpec.describe IndexFiltersController do
      routes { Engine.routes }

      states = %w(running paused completed aborted failed queued scheduled)

      states.each_with_index do |state, i|
        describe "GET ##{state}" do
          describe "with no #{state} jobs" do
            before do
              get state.to_sym
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it 'renders template' do
              expect(response).to render_template(state)
            end

            it "returns no jobs" do
              expect(assigns(:jobs).count).to eq(0)
            end
          end

          describe "with #{state} jobs" do
            let(:not_state) { states[i-1] }
            let(:state_job) {
              if state == 'scheduled'
                RocketJob::Job.create(state: :queued, run_at: Date.tomorrow)
              else
                RocketJob::Job.create(state: state)
              end
            }

            before do
              RocketJob::Job.create(state: not_state)
              get state.to_sym
            end

            after do
              RocketJob::Worker.delete_all
              RocketJob::Job.delete_all
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it 'renders template' do
              expect(response).to render_template(state)
            end

            it "grabs a filtered list of rocket jobs" do
              expect(assigns(:jobs)).to match_array([state_job])
            end
          end
        end
      end
    end
  end
end
