require 'rails_helper'

module RocketJobMissionControl
  module Workers
    RSpec.describe IndexFiltersController do
      routes { Engine.routes }

      states = %w(starting running paused stopping)

      states.each_with_index do |state, i|
        describe "GET ##{state}" do
          describe "with no #{state} workers" do
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
              expect(assigns(:workers).count).to eq(0)
            end
          end

          describe "with #{state} workers" do
            let(:not_state) { states[i-1] }
            let!(:state_dirmon) { RocketJob::Worker.create!(state: state) }

            before do
              RocketJob::Worker.create!(state: not_state)
              get state.to_sym
            end

            after do
              DatabaseCleaner.clean
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it 'renders template' do
              expect(response).to render_template(state)
            end

            it "grabs a filtered list of workers" do
              expect(assigns(:workers)).to match_array([state_dirmon])
            end
          end
        end
      end
    end
  end
end
