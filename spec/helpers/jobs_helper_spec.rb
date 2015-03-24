require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe JobsHelper, type: :helper do
    describe "#job_class" do
      let(:job) { double(:job, state: job_state) }

      {
        queued:    "warning",
        running:   "primary",
        completed: "success",
        aborted:   "warning",
        failed:    "danger",
      }.each do |state, expected_class|
        context "when job state is #{state}" do
          let(:job_state) { state }

          it "returns the correct class" do
            expect(helper.job_class(job)).to eq(expected_class)
          end
        end
      end
    end
  end
end
