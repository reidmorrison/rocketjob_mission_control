require_relative "../../test_helper"

module RocketJobMissionControl
  class ApplicationHelperTest < ActionView::TestCase
    describe ApplicationHelper do
      describe "#state_icon" do
        RocketJobMissionControl::ApplicationHelper::STATE_ICON_MAP.each do |state, expected_class|
          describe "when the job state is #{state}" do
            it "returns the correct class" do
              assert_equal "#{expected_class} #{state}", state_icon(state)
            end
          end
        end
      end

      describe "#pretty_print_array_or_hash" do
        let(:arguments) { [42, "muad'dib"] }
        let(:helper_output) { pretty_print_array_or_hash(arguments) }

        describe "when arguments is a simple array" do
          it "returns a string with spacing and line breaks" do
            assert_equal "[<br />  42,<br />  \"muad'dib\"<br />]", helper_output
          end
        end

        describe "when arguments is an array with complex data" do
          let(:arguments) do
            [
              42,
              {
                crew:       %w[leela fry bender],
                created_at: "1999-03-28"
              }
            ]
          end

          it "returns a string with spacing and line breaks" do
            expected_output = "[<br />  42,<br />  {<br />    \"crew\": [<br />      \"leela\",<br />      \"fry\",<br />      \"bender\"<br />    ],<br />    \"created_at\": \"1999-03-28\"<br />  }<br />]"
            assert_equal expected_output, helper_output
          end
        end

        describe "when arguments isn't an array or hash" do
          let(:arguments) { 42 }

          it "returns the arguments" do
            assert_equal arguments, helper_output
          end
        end
      end
    end
  end
end
