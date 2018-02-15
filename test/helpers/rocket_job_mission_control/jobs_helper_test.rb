require_relative '../../test_helper'

module RocketJobMissionControl
  JobsHelper.include(RocketJobMissionControl::ApplicationHelper)

  class JobsHelperTest < ActionView::TestCase
    describe JobsHelper do
      describe '#jobs_icon' do
        let :job do
          RocketJob::Jobs::SimpleJob.new
        end

        it 'shows queued' do
          assert_equal 'fa-inbox queued', job_icon(job)
        end

        it 'shows running' do
          job.start
          job.worker_name = 'test_worker'
          assert_equal 'fa-play running', job_icon(job)
        end

        it 'shows sleeping' do
          job.start
          assert_equal 'fa-hourglass sleeping', job_icon(job)
        end

        it 'shows failed' do
          job.start
          job.fail
          assert_equal 'fa-exclamation-triangle failed', job_icon(job)
        end

        it 'shows aborted' do
          job.start
          job.abort
          assert_equal 'fa-stop aborted', job_icon(job)
        end

        it 'handles scheduled special case' do
          job.run_at = 1.day.from_now
          assert_equal 'fa-clock scheduled', job_icon(job)
        end
      end

      describe '#jobs_states' do
        it 'returns the states' do
          assert_equal %w(queued running completed paused failed aborted), job_states
        end
      end

      describe '#job_states_with_scheduled' do
        it 'returns the states with scheduled' do
          assert_equal %w(scheduled queued running completed paused failed aborted), job_states_with_scheduled
        end
      end

      describe '#job_counts_by_state' do
        it 'returns job counts for a state' do
          RocketJob::Job.delete_all
          RocketJob::Jobs::SimpleJob.create!
          assert_equal 1, job_counts_by_state(:queued), RocketJob::Job.counts_by_state
          assert_equal 0, job_counts_by_state(:running), RocketJob::Job.counts_by_state
        end
      end

      describe '#job_action_link' do
        let(:action) { 'abort' }
        let(:http_method) { :patch }
        let(:path) { "/jobs/42/#{action}" }
        let(:action_link) { job_action_link(action, path, http_method) }

        it 'uses the action as the label' do
          assert_match />abort<\/a>/, action_link
        end

        it 'links to the correct url' do
          assert_match /href="\/jobs\/42\/abort\"/, action_link
        end

        it 'adds prompt for confirmation' do
          assert_match /data-confirm="Are you sure you want to abort this job\?"/, action_link
        end

        it 'uses correct http method' do
          assert_match /data-method="patch"/, action_link
        end
      end
    end
  end
end
