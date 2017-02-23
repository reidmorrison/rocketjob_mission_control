require_relative '../../test_helper'

class JobSanitizerTest < Minitest::Test

  class SimpleJob < RocketJob::Job
    def perform
    end
  end

  describe RocketJobMissionControl::JobSanitizer do
    before do
    end

    after do
    end

    describe '.sanitize' do
      it 'strips blank values' do
      end

      it 'nils blank values' do
      end

      it 'parses JSON' do
      end

      it 'sets the error for invalid JSON' do
      end
    end

  end
end
