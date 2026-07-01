# A recurring, cron scheduled job.
#
# Demonstrates the Scheduled jobs view and the cron schedule detail.
class ReportJob < RocketJob::Job
  include RocketJob::Plugins::Cron

  # Every weekday at 06:00 Eastern.
  self.cron_schedule = "0 6 * * 1-5 America/New_York"
  self.description   = "Generate and email the daily sales report"
  self.priority      = 30

  field :report_type, type: String, default: "daily", user_editable: true
  field :recipients,  type: Array,  default: [], user_editable: true
  field :include_charts, type: Mongoid::Boolean, default: true, user_editable: true

  validates :report_type, inclusion: %w[daily weekly monthly]

  def perform
    # Pretend to build a report.
  end
end
