require_relative "../../test_helper"

class DirmonSanitizerTest < Minitest::Test
  describe RocketJobMissionControl::DirmonSanitizer do
    class SampleJob < RocketJob::Job
      include RocketJob::Batch

      input_category format: :csv
      output_category format: :csv
      output_category name: :errors, format: :csv

      field :client_name, type: String, user_editable: true
      field :zip_code, type: Integer, user_editable: true

      self.destroy_on_complete = false

      def perform(record)
        record
      end
    end

    # A job class that gives its category a schema.
    class SchemaJob < RocketJob::Job
      include RocketJob::Batch

      SCHEMA = {"fields" => [{"name" => "name"}]}.freeze

      input_category format: :csv, schema: SCHEMA

      def perform(record)
        record
      end
    end

    let :sample_job do
      SampleJob.new
    end

    let :job_class_name do
      SampleJob.name
    end

    let :properties do
      {
        client_name:                  "Jack",
        zip_code:                     12_345,
        input_categories_attributes:  {0 => {format: :json}},
        output_categories_attributes: {0 => {name: :errors, format: :json}}
      }
    end

    let :sanitized_properties do
      {
        client_name:       "Jill",
        zip_code:          45_673,
        input_categories:  [{name: "main", format: "json", slice_size: 100, skip_unknown: "false"}],
        output_categories: [{name: "errors", format: "json"}]
      }
    end

    let :dirmon_entry do
      RocketJob::DirmonEntry.new(
        name:           "Test",
        job_class_name: job_class_name,
        pattern:        "the_path",
        properties:     properties
      )
    end

    describe ".sanitize" do
      it "passes permissible fields" do
        params   = {
          name:              "Test2",
          job_class_name:    job_class_name,
          pattern:           "another/path",
          archive_directory: "archive/path",
          properties:        properties
        }
        cleansed = RocketJobMissionControl::DirmonSanitizer.sanitize(params, SampleJob, dirmon_entry)

        assert_equal 0, dirmon_entry.errors.count
        expected = {archive_directory: "archive/path", job_class_name: "DirmonSanitizerTest::SampleJob", name: "Test2", pattern: "another/path", properties: {client_name: "Jack", zip_code: 12_345, input_categories: [{format: "json"}], output_categories: [{name: "errors", format: "json"}]}}

        assert_equal expected, cleansed
      end

      it "strips blank values" do
        params   = {
          name:              "",
          job_class_name:    "",
          pattern:           "",
          archive_directory: "",
          bad_field:         "Not permissible",
          properties:        {
            client_name:                  "",
            zip_code:                     "",
            input_categories_attributes:  {0 => {format: ""}},
            output_categories_attributes: {0 => {name: "", format: ""}}
          }
        }
        cleansed = RocketJobMissionControl::DirmonSanitizer.sanitize(params, SampleJob, dirmon_entry)

        assert_equal 0, dirmon_entry.errors.count
        expected = {}

        assert_equal expected, cleansed
      end
    end

    describe ".diff_category" do
      it "returns only different values" do
        default_category = sample_job.input_category
        properties       = {
          name:         "main",
          format:       "psv",
          slice_size:   100,
          skip_unknown: false
        }
        updated_category = RocketJob::Category::Input.new(properties)

        diff = RocketJobMissionControl::DirmonSanitizer.diff_category(properties, updated_category, default_category)

        expected = {format: "psv", name: "main"}

        assert_equal expected, diff
      end

      it "is empty with no changes" do
        default_category = sample_job.input_category
        properties       = {
          name:         "main",
          format:       "csv",
          slice_size:   100,
          skip_unknown: false
        }
        updated_category = RocketJob::Category::Input.new(properties)

        diff = RocketJobMissionControl::DirmonSanitizer.diff_category(properties, updated_category, default_category)

        expected = {}

        assert_equal expected, diff
      end

      it "empty" do
        default_category = sample_job.input_category
        properties       = {}
        updated_category = RocketJob::Category::Input.new(properties)

        diff = RocketJobMissionControl::DirmonSanitizer.diff_category(properties, updated_category, default_category)

        expected = {}

        assert_equal expected, diff
      end
    end

    describe ".diff_properties" do
      it "returns only different values" do
        diff     = RocketJobMissionControl::DirmonSanitizer.diff_properties(sanitized_properties, dirmon_entry)
        expected = {client_name: "Jill", zip_code: 45_673, input_categories: [{format: "json", name: "main"}], output_categories: [{format: "json", name: "errors"}]}

        assert_equal expected, diff
      end

      it "is empty without properties, such as when only the pattern of an entry for a batch job changed" do
        assert_empty RocketJobMissionControl::DirmonSanitizer.diff_properties(nil, dirmon_entry)
      end
    end

    describe ".update_properties" do
      let :saved_entry do
        RocketJob::DirmonEntry.new(
          name:           "Test",
          job_class_name: job_class_name,
          pattern:        "the_path",
          properties:     {
            "client_name"       => "Jack",
            "zip_code"          => 12_345,
            "input_categories"  => [{"format" => "json", "allowed_columns" => %w[name]}],
            "output_categories" => [{"name" => "errors", "format" => "json"}]
          }
        )
      end

      def update_properties(posted)
        sanitized = RocketJobMissionControl::DirmonSanitizer.sanitize({properties: posted}, SampleJob, saved_entry)[:properties]
        RocketJobMissionControl::DirmonSanitizer.update_properties(posted, sanitized, saved_entry)
      end

      it "keeps every property without any posted" do
        assert_equal saved_entry.properties, RocketJobMissionControl::DirmonSanitizer.update_properties(nil, nil, saved_entry)
      end

      it "sets a posted property, and keeps those not posted" do
        expected = saved_entry.properties.merge("client_name" => "Jill")

        assert_equal expected, update_properties({client_name: "Jill"})
      end

      it "removes a posted property that is blank" do
        assert_equal saved_entry.properties.except("client_name"), update_properties({client_name: ""})
      end

      it "finds a category without a name as main, and keeps what was not posted" do
        properties = update_properties(input_categories_attributes: {"0" => {name: "main", format: "psv"}})

        assert_equal [{"format" => "psv", "allowed_columns" => %w[name]}], properties["input_categories"]
      end

      it "removes a category left with only its name" do
        properties = update_properties(output_categories_attributes: {"0" => {name: "errors", format: "csv"}})

        assert_not properties.key?("output_categories")
      end

      it "adds a category that was not saved" do
        properties = update_properties(output_categories_attributes: {"0" => {name: "main", format: "json"}})

        assert_equal [{"name" => "errors", "format" => "json"}, {"name" => "main", "format" => "json"}],
                     properties["output_categories"]
      end

      it "removes the options that the schema that the job class gives a category replaces" do
        entry     = RocketJob::DirmonEntry.new(
          name:           "Test",
          job_class_name: SchemaJob.name,
          pattern:        "the_path",
          properties:     {"input_categories" => [{"name" => "main", "allowed_columns" => %w[name], "header_cleanser" => "none"}]}
        )
        # As the form posts it, with the schema of the job class.
        posted    = {input_categories_attributes: {"0" => {name: "main", format: "csv", schema: SchemaJob::SCHEMA.to_json}}}
        sanitized = RocketJobMissionControl::DirmonSanitizer.sanitize_properties(posted, SchemaJob, entry)

        assert_empty RocketJobMissionControl::DirmonSanitizer.update_properties(posted, sanitized, entry)
      end
    end
  end
end
