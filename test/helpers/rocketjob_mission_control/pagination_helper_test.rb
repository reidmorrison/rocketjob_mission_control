require_relative "../../test_helper"

module RocketjobMissionControl
  class PaginationHelperTest < ActionView::TestCase
    describe PaginationHelper do
      describe "#page_nav_disabled_class" do
        describe "when the current position equals the boundary" do
          it "returns disabled" do
            assert_equal "disabled", page_nav_disabled_class(0, 0)
          end
        end

        describe "when the current position is NOT equal to the boundary" do
          it "returns blank" do
            assert page_nav_disabled_class(4, 0).blank?
          end
        end
      end
    end
  end
end
