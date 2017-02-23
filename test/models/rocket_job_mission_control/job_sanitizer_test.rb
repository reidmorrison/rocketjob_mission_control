require_relative '../../test_helper'

class JobSanitizerTest < Minitest::Test

  class SimpleJob < RocketJob::Job
    field :hash, type: Hash, user_editable: true
    field :string, type: String, user_editable: true
    field :integer, type: Integer, user_editable: true
    field :symbol, type: Symbol, user_editable: true
    field :secure, type: String

    def perform
    end
  end

  describe RocketJobMissionControl::JobSanitizer do
    before do
      @job = SimpleJob.new
      assert_equal 0, @job.errors.count
    end

    after do
    end

    describe '.sanitize' do
      it 'passes permissable fields' do
        properties = {
          string:  'hello',
          integer: '12',
          symbol:  'name',
          secure:  'Not permissible'
        }
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)
        assert_equal 0, @job.errors.count
        assert_equal 3, cleansed.count
        assert_equal({:string=>"hello", :integer=>"12", :symbol=>"name"}, cleansed)
      end

      it 'strips blank values' do
        properties = {
          string:  '',
          integer: '',
          symbol:  '',
          secure:  'Not permissible',
          log_level: ''
        }
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)
        assert_equal 0, @job.errors.count
        assert_equal 0, cleansed.count
      end

      it 'nils blank values' do
        properties = {
          string:  '',
          integer: '',
          symbol:  '',
          secure:  'Not permissible',
          log_level: ''
        }
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, true)
        assert_equal 0, @job.errors.count
        assert_equal 4, cleansed.count
        assert_equal({log_level: nil, integer: nil, string: nil, symbol: nil}, cleansed)
      end

      it 'parses JSON' do
        properties = {
          string:  '',
          secure:  'Not permissible',
          hash:    '{"state":"FL"}'
        }
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)
        assert_equal 0, @job.errors.count
        assert_equal 1, cleansed.count
        assert_equal({'state' => 'FL'}, cleansed[:hash])
      end

      it 'sets the error for invalid JSON' do
        properties = {
          string:  'hello',
          secure:  'Not permissible',
          hash:    '{ bad json }'
        }
        cleansed   = RocketJobMissionControl::JobSanitizer.sanitize(properties, @job.class, @job, false)
        assert_equal 1, @job.errors.count
        assert first = @job.errors.first
        assert_equal first.first, :properties
        assert first.second.include?('unexpected token'), first
        assert_equal 1, cleansed.count
        assert_equal({string: 'hello'}, cleansed)
      end
    end

  end
end
