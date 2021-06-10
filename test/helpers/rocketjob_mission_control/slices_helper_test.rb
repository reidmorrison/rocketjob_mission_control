require_relative "../../test_helper"

module RocketjobMissionControl
  SlicesHelper.include(RocketjobMissionControl::ApplicationHelper)
  class SlicesHelperTest < ActionView::TestCase
    describe SlicesHelper do
      describe "#display_slice_info" do
        let(:slice) { {id: 42, name: "test"} }

        describe "when encrypted" do
          it "only shows encrypted text" do
            assert_equal "encrypted", display_slice_info(slice, true)
          end
        end

        describe "when not encrypted" do
          it "does not return 'encrypted'" do
            refute_equal "encrypted", display_slice_info([1, 2], false)
          end

          it "displays the slice info" do
            assert_equal "[<br />  1,<br />  2<br />]", display_slice_info([1, 2], false)
          end
        end
      end
    end
  end
end
