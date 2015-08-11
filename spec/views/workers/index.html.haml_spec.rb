require 'rails_helper'

module RocketJobMissionControl
  class FakeWorker < OpenStruct
  end

  RSpec.describe 'rocket_job_mission_control/workers/index.html.haml', type: :view do
    before do
      assign(:workers, [
        FakeWorker.new(
          name: 'Worker42',
          heartbeat: spy(current_threads: 42),
          started_at: 1.minute.ago,
        ),
      ])
      render
    end

    it 'displays the worker' do
      expect(rendered).to include('Worker42')
    end
  end
end
