require_relative "../../test_helper"

module RocketJobMissionControl
  # The encoding of a category's files is picked with tom-select, which suggests the common encodings and takes any
  # other that is typed in.
  class CategoryEncodingTest < SystemTestCase
    # Types into the tom-select control that replaces the first input category's encoding select.
    def type_encoding(text)
      select = find("select[name*='input_categories_attributes'][name$='[encoding]']", visible: :all)
      find("##{select[:id]}-ts-control").send_keys(text)
    end

    # Adds the typed text as an encoding that is not suggested.
    def add_typed_encoding(text)
      type_encoding(text)
      find(".ts-dropdown .create").click
    end

    describe "the encoding of a job's category" do
      before do
        RocketJob::Job.delete_all
      end

      let :job do
        CSVJob.create!
      end

      it "is picked from the suggested encodings" do
        visit edit_job_path(job)

        type_encoding("Windows-12")
        find(".ts-dropdown .option", text: "Windows-1252", exact_text: true).click
        click_on "Save"

        assert_text "Windows-1252"
        assert_equal "Windows-1252", job.reload.input_category.encoding
      end

      it "is typed in when it is not suggested" do
        visit edit_job_path(job)

        add_typed_encoding("EUC-JP")
        click_on "Save"

        assert_text "EUC-JP"
        assert_equal "EUC-JP", job.reload.input_category.encoding
      end

      it "shows why an encoding is not valid" do
        visit edit_job_path(job)

        add_typed_encoding("UTF-16")
        click_on "Save"

        assert_text "Failed to save the changes!"
        assert_text "so name its byte order, such as UTF-16LE"
        assert_nil job.reload.input_category.encoding
      end
    end

    describe "the encoding of a Dirmon entry's files" do
      before do
        RocketJob::DirmonEntry.delete_all
      end

      let :dirmon_entry do
        RocketJob::DirmonEntry.create!(name: "Import", job_class_name: "DataImportJob", pattern: "import/*.csv")
      end

      it "is saved" do
        visit edit_dirmon_entry_path(dirmon_entry)

        add_typed_encoding("EUC-JP")
        click_on "update"

        assert_text "EUC-JP"
        assert_equal "EUC-JP", dirmon_entry.reload.properties["input_categories"].first["encoding"]
      end

      it "shows why an encoding is not valid" do
        visit edit_dirmon_entry_path(dirmon_entry)

        add_typed_encoding("UTF-16")
        click_on "update"

        assert_text "Invalid Dirmon entry!"
        assert_text "so name its byte order, such as UTF-16LE"
        assert_empty dirmon_entry.reload.properties
      end
    end
  end
end
