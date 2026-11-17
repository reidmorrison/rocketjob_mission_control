require_relative "../../test_helper"

class JobSanitizerTest < Minitest::Test
  describe RocketJobMissionControl::JobSanitizer do
    before do
      @job = AllTypesJob.new

      assert_equal 0, @job.errors.count
    end

    after do
    end

    describe ".sanitize" do
      it "passes permissible fields" do
        properties = {
          string:  "hello",
          integer: "12",
          symbol:  "name",
          secure:  "Not permissible"
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 0, @job.errors.count
        assert_equal 3, cleansed.count
        assert_equal({string: "hello", integer: "12", symbol: "name"}, cleansed)
      end

      it "replaces the \\r\\n line breaks that a browser posts with \\n" do
        properties = {string: "line 1\r\nline 2", symbol: "line 1\r\nline 2"}
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal({string: "line 1\nline 2", symbol: "line 1\nline 2"}, cleansed)
      end

      it "strips blank values" do
        properties = {
          string:    "",
          integer:   "",
          symbol:    "",
          secure:    "Not permissible",
          log_level: ""
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 0, @job.errors.count
        assert_equal 0, cleansed.count
      end

      it "nils blank values" do
        properties = {
          string:     "",
          integer:    "",
          symbol:     "",
          hash_field: "",
          secure:     "Not permissible",
          log_level:  ""
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, true)

        assert_equal 0, @job.errors.count, @job.errors
        assert_equal 5, cleansed.count
        assert_equal({log_level: nil, hash_field: nil, integer: nil, string: nil, symbol: nil}, cleansed)
      end

      it "parses JSON" do
        properties = {
          string:     "",
          secure:     "Not permissible",
          hash_field: '{"state":"FL"}'
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 0, @job.errors.count
        assert_equal 1, cleansed.count
        assert_equal({"state" => "FL"}, cleansed[:hash_field])
      end

      it "sets the error for invalid JSON" do
        properties = {
          string:     "hello",
          secure:     "Not permissible",
          hash_field: "{ bad json }"
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 1, @job.errors.count
        assert error = @job.errors.first
        assert_equal :properties, error.attribute
        assert_predicate error.message, :present?, error
        assert_equal({string: "hello"}, cleansed)
      end

      it "Keeps empty JSON Hash" do
        properties = {
          hash_field: "{ }"
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 0, @job.errors.count
        assert_equal({hash_field: {}}, cleansed)
      end

      it "removes blank entries from rails converted arrays when using multi-select input" do
        properties = {
          array: ["", "rf@exp.com", "rm@exp.com", "lb@exp.com"]
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)

        assert_equal 0, @job.errors.count
        assert_equal({array: ["rf@exp.com", "rm@exp.com", "lb@exp.com"]}, cleansed)
      end
    end

    describe ".posted_fields" do
      it "lists the user editable fields that were posted, also those posted blank" do
        assert_equal %i[string], RocketJobMissionControl::JobSanitizer.posted_fields({string: "", secure: "x"}, @job.class)
      end
    end

    describe ".posted_categories" do
      it "lists each posted category, main without a name, with the fields that were posted, also those posted blank" do
        properties = {
          input_categories_attributes:  {"0" => {format: "", unknown: "x"}},
          output_categories_attributes: {"1" => {name: "errors", columns: ["", "name"]}}
        }
        posted = RocketJobMissionControl::JobSanitizer.posted_categories(properties).collect(&:to_a)

        assert_equal [[:input_categories, RocketJob::Category::Input, "main", %i[format]],
                      [:output_categories, RocketJob::Category::Output, "errors", %i[columns]]], posted
      end
    end

    describe ".sanitize_categories" do
      it "parses the JSON of a schema" do
        properties = {"0" => {name: "main", schema: %({"fields": [{"name": "name"}]}\n)}}

        assert_equal [{name: "main", schema: {"fields" => [{"name" => "name"}]}}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input)
      end

      it "keeps the path or url of a schema" do
        properties = {"0" => {name: "main", schema: " s3://bucket/schemas/people.json "}}

        assert_equal [{name: "main", schema: "s3://bucket/schemas/people.json"}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input)
      end

      it "keeps validate_rows as a Boolean" do
        properties = {"0" => {name: "main", validate_rows: "true"}, "1" => {name: "other", validate_rows: "false"}}

        assert_equal [{name: "main", validate_rows: true}, {name: "other", validate_rows: false}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input)
      end

      it "clears a blank validate_rows" do
        assert_equal [{name: "main", validate_rows: nil}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories({"0" => {name: "main", validate_rows: ""}},
                                                                               RocketJob::Category::Input)
        assert_equal [{name: "main"}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories({"0" => {name: "main", validate_rows: ""}},
                                                                               RocketJob::Category::Input, false)
      end

      it "clears a blank schema" do
        assert_equal [{name: "main", schema: nil}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories({"0" => {name: "main", schema: ""}},
                                                                               RocketJob::Category::Input)
      end

      it "removes the blank entry that a multi-select posts from the columns" do
        properties = {"0" => {name: "main", columns: ["", "name", "age"]}}

        assert_equal [{name: "main", columns: %w[name age]}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input)
      end

      it "leaves out columns with none selected" do
        assert_equal [{name: "main"}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories({"0" => {name: "main", columns: [""]}},
                                                                               RocketJob::Category::Input)
      end

      it "leaves out a schema that is not valid JSON, and sets the error" do
        properties = {"0" => {name: "main", schema: "{ bad json"}}

        assert_equal [{name: "main"}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input, true, @job)
        assert_equal :properties, @job.errors.first.attribute
        assert_includes @job.errors.first.message, "Schema is not valid JSON"
      end

      it "converts each value by its field in the category class" do
        properties = {"0" => {name: "main", skip_unknown: "true", slice_size: "10"}}

        assert_equal [{name: "main", skip_unknown: true, slice_size: 10}],
                     RocketJobMissionControl::JobSanitizer.sanitize_categories(properties, RocketJob::Category::Input)
      end
    end
  end
end
