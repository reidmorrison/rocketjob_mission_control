require_relative "../../test_helper"

module RocketJobMissionControl
  class DirmonEntriesHelperTest < ActionView::TestCase
    describe DirmonEntriesHelper do
      describe "#dirmon_counts_by_state" do
        it "returns the count for a state, defaulting to zero" do
          RocketJob::DirmonEntry.delete_all
          RocketJob::DirmonEntry.create!(name: "test", pattern: "/tmp/*", job_class_name: "AllTypesJob")
          assert_equal 1, dirmon_counts_by_state(:pending)
          assert_equal 0, dirmon_counts_by_state(:failed)
        end
      end

      describe "#dirmon_entry_find_category" do
        let(:categories) { [{"name" => "main"}, {"name" => "errors"}] }

        it "returns nil when categories is nil" do
          assert_nil dirmon_entry_find_category(nil)
        end

        it "defaults to the main category" do
          assert_equal({"name" => "main"}, dirmon_entry_find_category(categories))
        end

        it "finds a named category" do
          assert_equal({"name" => "errors"}, dirmon_entry_find_category(categories, :errors))
        end

        it "treats a nameless category as main" do
          assert_equal({}, dirmon_entry_find_category([{}], :main))
        end

        it "returns nil when no category matches" do
          assert_nil dirmon_entry_find_category(categories, :missing)
        end
      end

      describe "#rocket_job_mission_control" do
        it "exposes the engine url helpers" do
          assert_respond_to rocket_job_mission_control, :jobs_path
        end
      end
    end
  end
end
