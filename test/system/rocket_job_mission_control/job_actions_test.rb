require_relative "../../test_helper"

module RocketJobMissionControl
  class JobActionsTest < SystemTestCase
    class PausableJob < RocketJob::Job
      self.pausable = true

      def perform
        21
      end
    end

    describe "job action links" do
      before do
        RocketJob::Job.delete_all
      end

      let :job do
        PausableJob.create!
      end

      it "pauses a running job" do
        job.start!
        visit job_path(job)

        accept_confirm { click_on "Pause" }

        assert_text "Paused"
        assert_equal :paused, job.reload.state
      end

      it "resumes a paused job" do
        job.start!
        job.pause!
        visit job_path(job)

        accept_confirm { click_on "Resume" }

        assert_equal :running, job.reload.state
      end

      it "fails a running job" do
        job.start!
        visit job_path(job)

        accept_confirm { click_on "Fail" }

        assert_equal :failed, job.reload.state
      end

      it "retries a failed job" do
        job.start!
        job.fail!
        visit job_path(job)

        accept_confirm { click_on "Retry" }

        assert_not_equal :failed, job.reload.state
      end

      it "aborts a running job" do
        job.start!
        visit job_path(job)

        accept_confirm { click_on "Abort" }

        assert_equal :aborted, job.reload.state
      end

      it "runs a scheduled job now" do
        scheduled_job = RocketJob::Jobs::SimpleJob.create!(run_at: 2.days.from_now)
        visit job_path(scheduled_job)

        accept_confirm { click_on "Run" }

        assert_nil scheduled_job.reload.run_at
      end

      it "destroys a job" do
        job_id = job.id
        visit job_path(job)

        accept_confirm { click_on "Destroy" }

        assert_nil RocketJob::Job.where(id: job_id).first
      end
    end
  end
end
