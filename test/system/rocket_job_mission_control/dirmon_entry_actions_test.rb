require_relative "../../test_helper"

module RocketJobMissionControl
  class DirmonEntryActionsTest < SystemTestCase
    describe "dirmon entry action links" do
      before do
        RocketJob::DirmonEntry.delete_all
      end

      let :dirmon_entry do
        RocketJob::DirmonEntry.create!(
          name:           "System test entry",
          job_class_name: "RocketJob::Jobs::SimpleJob",
          pattern:        "system_test_path"
        )
      end

      it "enables a pending entry" do
        visit dirmon_entry_path(dirmon_entry)

        accept_confirm { click_on "Enable" }

        assert dirmon_entry.reload.enabled?
      end

      it "disables an enabled entry" do
        dirmon_entry.enable!
        visit dirmon_entry_path(dirmon_entry)

        accept_confirm { click_on "Disable" }

        assert dirmon_entry.reload.disabled?
      end

      it "destroys an entry" do
        entry_id = dirmon_entry.id
        visit dirmon_entry_path(dirmon_entry)

        accept_confirm { click_on "Destroy" }

        assert_not RocketJob::DirmonEntry.where(id: entry_id).exists?
      end
    end
  end
end
