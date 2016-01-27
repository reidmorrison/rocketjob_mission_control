require 'rails_helper'

module RocketJobMissionControl
  class ::TheJobClass < OpenStruct;
  end

  RSpec.describe JobsHelper, type: :helper do
    before do
      helper.extend(RocketJobMissionControl::ApplicationHelper)
    end

    describe '#state_icon' do
      JobsHelper::STATE_ICON_MAP.each do |state, expected_class|
        context "when the job state is #{state}" do
          it 'returns the correct class' do
            expect(helper.state_icon(state)).to eq("#{expected_class} #{state}")
          end
        end
      end
    end

    describe '#job_action_link' do
      let(:action) { 'abort' }
      let(:http_method) { :patch }
      let(:path) { "/jobs/42/#{action}" }
      let(:action_link) { helper.job_action_link(action, path, http_method) }

      it 'uses the action as the label' do
        expect(action_link).to match(/>abort<\/a>/)
      end

      it 'links to the correct url' do
        expect(action_link).to match(/href="\/jobs\/42\/abort\"/)
      end

      it 'adds prompt for confirmation' do
        expect(action_link).to match(/data-confirm="Are you sure you want to abort this job\?"/)
      end

      it 'uses correct http method' do
        expect(action_link).to match(/data-method="patch"/)
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

  end
end
