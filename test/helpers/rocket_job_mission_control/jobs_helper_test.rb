require_relative "../../test_helper"

module RocketJobMissionControl
  JobsHelper.include(RocketJobMissionControl::ApplicationHelper)

  class JobsHelperTest < ActionView::TestCase
    describe JobsHelper do
      describe "#jobs_icon" do
        let :job do
          RocketJob::Jobs::SimpleJob.new
        end

        it "shows queued" do
          assert_equal "fas fa-inbox queued", job_icon(job)
        end

        it "shows running" do
          job.start
          job.worker_name = "test_worker"
          assert_equal "fas fa-play running", job_icon(job)
        end

        it "shows sleeping" do
          job.start
          assert_equal "fas fa-hourglass sleeping", job_icon(job)
        end

        it "shows failed" do
          job.start
          job.fail
          assert_equal "fas fa-exclamation-triangle failed", job_icon(job)
        end

        it "shows aborted" do
          job.start
          job.abort
          assert_equal "fas fa-stop aborted", job_icon(job)
        end

        it "handles scheduled special case" do
          job.run_at = 1.day.from_now
          assert_equal "fas fa-clock scheduled", job_icon(job)
        end
      end

      describe "#jobs_states" do
        it "returns the states" do
          assert_equal %w[queued running completed paused failed aborted], job_states
        end
      end

      describe "#job_states_with_scheduled" do
        it "returns the states with scheduled" do
          assert_equal %w[scheduled queued running completed paused failed aborted], job_states_with_scheduled
        end
      end

      describe "#job_counts_by_state" do
        it "returns job counts for a state" do
          RocketJob::Job.delete_all
          RocketJob::Jobs::SimpleJob.create!
          assert_equal 1, job_counts_by_state(:queued), RocketJob::Job.counts_by_state
          assert_equal 0, job_counts_by_state(:running), RocketJob::Job.counts_by_state
        end
      end

      describe "#job_total_slices" do
        it "returns nil when the record count is unknown" do
          assert_nil job_total_slices(KaboomBatchJob.new)
        end

        it "divides the record count by the slice size, rounding up" do
          job = KaboomBatchJob.new
          job.input_category.slice_size = 100
          job.record_count = 250
          assert_equal 3, job_total_slices(job)
        end
      end

      describe "#job_slice_stats" do
        let :batch_job do
          job = KaboomBatchJob.new
          job.input_category.slice_size = 1
          job.upload do |stream|
            stream << "first record"
            stream << "second record"
            stream << "third record"
          end
          job.save!
          job
        end

        after do
          RocketJob::Job.delete_all
        end

        it "returns the four ordered buckets" do
          labels = job_slice_stats(batch_job).map(&:first)
          assert_equal %w[Queued Active Failed Completed], labels
        end

        it "counts every uploaded slice as queued" do
          queued = job_slice_stats(batch_job).find { |bucket| bucket.first == "Queued" }
          assert_equal 3, queued[2]
          assert_in_delta 100.0, queued[3], 0.01
        end

        it "derives completed slices from the total minus those still in the queue" do
          batch_job.input.first.start!
          stats     = job_slice_stats(batch_job)
          completed = stats.find { |bucket| bucket.first == "Completed" }
          active    = stats.find { |bucket| bucket.first == "Active" }
          assert_equal 1, active[2]
          assert_equal 0, completed[2]
        end

        it "reports zero percentages when nothing is known" do
          percents = job_slice_stats(KaboomBatchJob.new).map(&:last)
          assert_equal [0, 0, 0, 0], percents
        end
      end

      describe "#job_action_link" do
        let(:action) { "abort" }
        let(:http_method) { :patch }
        let(:path) { "/jobs/42/#{action}" }
        let(:action_link) { job_action_link(action, path, http_method) }

        it "uses the action as the label" do
          assert_match %r{>abort</a>}, action_link
        end

        it "links to the correct url" do
          assert_match %r{href="/jobs/42/abort"}, action_link
        end

        it "adds prompt for confirmation" do
          assert_match(/data-confirm="Are you sure you want to abort this job\?"/, action_link)
        end

        it "uses correct http method" do
          assert_match(/data-method="patch"/, action_link)
        end
      end
    end
  end
end
