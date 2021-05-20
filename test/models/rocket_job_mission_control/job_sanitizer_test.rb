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
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, false)
        assert_equal 0, @job.errors.count
        assert_equal 3, cleansed.count
        assert_equal({string: "hello", integer: "12", symbol: "name"}, cleansed)
      end

      it "strips blank values" do
        properties = {
          string:    "",
          integer:   "",
          symbol:    "",
          secure:    "Not permissible",
          log_level: ""
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, false)
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
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, true)
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
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, false)
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
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, false)
        assert_equal 1, @job.errors.count
        if Rails.version.to_f >= 6.1
          assert error = @job.errors.first
          assert_equal error.attribute, :properties
          assert error.message.include?("unexpected token"), error
        else
          assert error = @job.errors.first
          assert_equal error.first, :properties
          assert error.second.include?("unexpected token"), error
        end
        assert_equal({hash_field: "{ bad json }", string: "hello"}, cleansed)
      end

      it "Keeps empty JSON Hash" do
        properties = {
          hash_field: "{ }"
        }
        cleansed = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, false)
        assert_equal 0, @job.errors.count
        assert_equal({hash_field: {}}, cleansed)
      end
    end
  end
end
