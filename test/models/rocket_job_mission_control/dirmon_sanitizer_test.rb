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

    let :sample_job do
      SampleJob.new
    end

    let :job_class_name do
      SampleJob.name
    end

    let :properties do
      {
        client_name:                  "Jack",
        zip_code:                     12345,
        input_categories_attributes:  {0 => {format: :json}},
        output_categories_attributes: {0 => {name: :errors, format: :json}}
      }
    end

    let :sanitized_properties do
      {
        client_name:       "Jill",
        zip_code:          45673,
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
        expected = {:archive_directory => "archive/path", :job_class_name => "DirmonSanitizerTest::SampleJob", :name => "Test2", :pattern => "another/path", :properties => {:client_name => "Jack", :zip_code => 12345, :input_categories => [{:format => :json}], :output_categories => [{:name => :errors, :format => :json}]}}
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

        expected = {:format => "psv", :name => "main"}
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
        expected = {:client_name => "Jill", :zip_code => 45673, :input_categories => [{:format => "json", :name => "main"}], :output_categories => [{:format => "json", :name => "errors"}]}
        assert_equal expected, diff
      end
    end
  end
end
