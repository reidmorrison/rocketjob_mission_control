require_relative '../../test_helper'

class JobFailuresTest < Minitest::Test

  if defined?(RocketJobPro)
    class BatchJob < RocketJob::Job
      include RocketJob::Plugins::Batch
      self.slice_size = 1

      def perform(record)
        raise "Failure: #{rocket_job_record_number}"
      end
    end
  end

  describe RocketJobMissionControl::JobFailures do
    before do
      skip 'Only tested with RocketJob Pro' unless defined?(RocketJobPro)

      @job = BatchJob.new
      @job.upload do |stream|
        stream << 'first record'
        stream << 'second record'
      end
      @job.save!

      @job_failures = RocketJobMissionControl::JobFailures.new(@job.id.to_s)
    end

    after do
      @job.destroy if @job && !@job.new_record?
    end

    describe '#job' do
      it 'looks up the job' do
        assert_equal @job.id.to_s, @job_failures.job.id.to_s
      end
    end

    describe '#list' do
      before do
        assert_raises RuntimeError do
          @job.perform_now
        end
      end

      it 'returns exceptions' do
        def list
          @slice_errors ||= job.input.group_exceptions
        end

        assert list = @job_failures.list
        assert_equal 1, list.count
        assert first = list.first
        assert_equal 'RuntimeError', first.class_name
        assert_equal 1, first.count
        assert_equal ['Failure: 1'], first.messages
      end
    end
  end
end
