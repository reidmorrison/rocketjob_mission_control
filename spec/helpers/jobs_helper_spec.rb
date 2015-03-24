require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe JobsHelper, type: :helper do
    describe "#job_state_icon" do
      {
        queued:     'fa-bed warning',
        running:    'fa-cog fa-spin primary',
        completed:  'fa-check-circle-o success',
        aborted:    'fa-times-circle-o warning',
        unexpected: 'fa-times-circle-o danger'
      }.each do |state, expected_class|
        context "when the job state is #{state}" do
          it "returns the correct class" do
            expect(helper.job_state_icon(state)).to eq(expected_class)
          end
        end
      end
    end

    describe "#job_class" do
      let(:job) { double(:job, state: job_state) }

      {
        queued:     "warning",
        running:    "primary",
        completed:  "success",
        aborted:    "warning",
        failed:     "danger",
        unexpected: "",
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
