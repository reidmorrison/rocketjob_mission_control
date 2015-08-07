require 'rails_helper'

module RocketJobMissionControl
  class ::TheJobClass < OpenStruct;
  end

  RSpec.describe JobsHelper, type: :helper do
    describe '#job_state_icon' do
      JobsHelper::STATE_ICON_MAP.each do |state, expected_class|
        context "when the job state is #{state}" do
          it 'returns the correct class' do
            expect(helper.job_state_icon(state)).to eq("#{expected_class} #{state}")
          end
        end
      end
    end

    describe '#pretty_print_array_or_hash' do
      let(:arguments) { [42, "muad'dib"] }
      let(:helper_output) { helper.pretty_print_array_or_hash(arguments) }

      context 'when arguments is a simple array' do
        it 'returns a string with spacing and line breaks' do
          expect(helper_output).to eq("[<br />  42,<br />  \"muad'dib\"<br />]")
        end
      end

      context 'when arguments is an array with complex data' do
        let(:arguments) {
          [
            42,
            {
              crew:       ['leela', 'fry', 'bender'],
              created_at: '1999-03-28',
            }
          ]
        }

        it 'returns a string with spacing and line breaks' do
          expected_output = "[<br />  42,<br />  {<br />    \"crew\": [<br />      \"leela\",<br />      \"fry\",<br />      \"bender\"<br />    ],<br />    \"created_at\": \"1999-03-28\"<br />  }<br />]"
          expect(helper_output).to eq(expected_output)
        end
      end

      context "when arguments isn't an array or hash" do
        let(:arguments) { 42 }

        it 'returns the arguments' do
          expect(helper_output).to eq(arguments)
        end
      end
    end

    describe '#job_title' do
      let(:perform_method) { :perform }
      let(:job) { TheJobClass.new(perform_method: perform_method, priority: 42) }

      context "with a job using the 'perform' perform_method" do
        it 'returns the correct string without the perform method' do
          expect(helper.job_title(job)).to eq('TheJobClass')
        end
      end

      context "with a job using a perform method that is not 'perform'" do
        let(:perform_method) { :bendit }

        it 'returns the correct string with the perform method' do
          expect(helper.job_title(job)).to eq("TheJobClass##{perform_method}")
        end
      end
    end
  end
end
