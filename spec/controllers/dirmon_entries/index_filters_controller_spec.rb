require 'rails_helper'

class AJob < RocketJob::Job
  def perform(id)
    id
  end
end

module RocketJobMissionControl
  module DirmonEntries
    RSpec.describe IndexFiltersController do
      routes { Engine.routes }

      states = %w(pending enabled failed disabled)

      states.each_with_index do |state, i|
        describe "GET ##{state}" do
          describe "with no #{state} dirmons" do
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
              expect(assigns(:dirmons).count).to eq(0)
            end
          end

          describe "with #{state} dirmons" do
            let(:not_state) { states[i-1] }
            let!(:state_dirmon) {
              RocketJob::DirmonEntry.create!(
                state:          state,
                pattern:        '21',
                arguments:      ['42'],
                job_class_name: 'AJob'
              )
            }

            before do
              RocketJob::DirmonEntry.create!(
                name:           'Test',
                state:          not_state,
                arguments:      ['42'],
                pattern:        '21',
                job_class_name: 'AJob'
              )
              get state.to_sym
            end

            after do
              RocketJob::DirmonEntry.delete_all
            end

            it "succeeds" do
              expect(response.status).to be(200)
            end

            it 'renders template' do
              expect(response).to render_template(state)
            end

            it "grabs a filtered list of dirmons" do
              expect(assigns(:dirmons)).to match_array([state_dirmon])

            end
          end
        end
      end
    end
  end
end
