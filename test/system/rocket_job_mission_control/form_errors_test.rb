require_relative "../../test_helper"

module RocketJobMissionControl
  # A form that could not be saved is rendered again with a 422 status, since Turbo Drive ignores a form response
  # that renders with 200, so nothing would appear to happen.
  class FormErrorsTest < SystemTestCase
    # Fills in the schema of the first input category.
    def fill_in_schema(text)
      find("textarea[name*='input_categories_attributes'][name$='[schema]']").set(text)
    end

    describe "the job form" do
      before do
        RocketJob::Job.delete_all
      end

      let :job do
        CSVJob.create!
      end

      it "shows why a category is not valid" do
        visit edit_job_path(job)

        fill_in_schema(JSON.generate("fields" => [{"name" => "name", "type" => "time"}]))
        click_on "Save"

        assert_text "Failed to save the changes!"
        assert_text "Schema is not valid"
        assert_nil job.reload.input_category.schema
      end
    end

    describe "the Dirmon entry form" do
      before do
        RocketJob::DirmonEntry.delete_all
      end

      let :dirmon_entry do
        RocketJob::DirmonEntry.create!(name: "Import", job_class_name: "DataImportJob", pattern: "import/*.csv")
      end

      it "shows why it could not be saved" do
        visit edit_dirmon_entry_path(dirmon_entry)

        fill_in_schema("{ bad json")
        click_on "update"

        assert_text "Invalid Dirmon entry!"
        assert_text "Schema is not valid JSON"
        assert_empty dirmon_entry.reload.properties
      end
    end
  end
end
