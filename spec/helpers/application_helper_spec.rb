require 'rails_helper'

module RocketJobMissionControl
  class ::TheJobClass < OpenStruct;
  end

  describe ApplicationHelper, type: :helper do
    before do
      helper.extend(RocketJobMissionControl::ApplicationHelper)
    end

    describe '#state_icon' do
      RocketJobMissionControl::ApplicationHelper::STATE_ICON_MAP.each do |state, expected_class|
        context "when the job state is #{state}" do
          it 'returns the correct class' do
            expect(helper.state_icon(state)).to eq("#{expected_class} #{state}")
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
  end
end
