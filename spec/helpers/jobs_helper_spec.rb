require 'rails_helper'

module RocketJobMissionControl
  RSpec.describe JobsHelper, type: :helper do
    #TODO: Timecop this for stability
    describe "#job_duration" do
      let(:job) { double(:job, completed?: false, aborted?: false, started_at: Time.now) }

      context "when the job is completed" do
        before do
          allow(job).to receive(:completed?).and_return(true)
          allow(job).to receive(:completed_at).and_return(1.minute.from_now)
        end

        it "returns the time between started at and completed at" do
          expect(helper.job_duration(job)).to eq('1 minute')
        end
      end

      context "when the job is aborted" do
        before do
          allow(job).to receive(:aborted?).and_return(true)
          allow(job).to receive(:completed_at).and_return(2.minutes.from_now)
        end

        it "returns the time between started at and aborted at" do
          expect(helper.job_duration(job)).to eq('2 minutes')
        end
      end

      context "when the job is not aborted or completed" do
        before do
          allow(job).to receive(:started_at).and_return(Time.now)
          allow(job).to receive(:completed_at).and_return(nil)
        end

        it "returns the time between started at and now" do
          expect(helper.job_duration(job)).to eq('5 seconds')
        end
      end
    end

    describe "#job_state_icon" do
      {
        queued:     'fa-bed warning',
        running:    'fa-cog fa-spin primary',
        completed:  'fa-check-circle-o success',
        aborted:    'fa-times-circle-o warning',
        unexpected: 'fa-times-circle-o danger',
        paused:     'fa-bed warning',
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
        paused:     "warning",
        running:    "primary",
        completed:  "success",
        aborted:    "danger",
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

    describe "#pretty_print_array_or_hash" do
      let(:arguments) { [42, "muad'dib"] }
      let(:helper_output) { helper.pretty_print_array_or_hash(arguments) }

      context "when arguments is a simple array" do
        it "returns a string with spacing and line breaks" do
          expect(helper_output).to eq("[<br />  42,<br />  \"muad'dib\"<br />]")
        end
      end

      context "when arguments is an array with complex data" do
        let(:arguments) {
          [
            42,
            {
              crew:       ['leela', 'fry', 'bender'],
              created_at: '1999-03-28',
            }
          ]
        }

        it "returns a string with spacing and line breaks" do
          expected_output = "[<br />  42,<br />  {<br />    \"crew\": [<br />      \"leela\",<br />      \"fry\",<br />      \"bender\"<br />    ],<br />    \"created_at\": \"1999-03-28\"<br />  }<br />]"
          expect(helper_output).to eq(expected_output)
        end
      end

      context "when arguments isn't an array or hash" do
        let(:arguments) { 42 }

        it "returns the arguments" do
          expect(helper_output).to eq(arguments)
        end
      end
    end

    describe '#job_title' do
      let(:perform_method) { :perform }
      let(:job) { OpenStruct.new(perform_method: perform_method, priority: 42, klass: 'TheJobClass') }

      context "with a job using the 'perform' perform_method" do
        it "returns the correct string without the perform method" do
          expect(helper.job_title(job)).to eq('42 - TheJobClass')
        end
      end

      context "with a job using a perform method that is not 'perform'" do
        let(:perform_method) { :bendit }

        it "returns the correct string with the perform method" do
          expect(helper.job_title(job)).to eq("42 - TheJobClass##{perform_method}")
        end
      end
    end
  end
end
