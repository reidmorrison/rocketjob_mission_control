class CSVJob < RocketJob::Job
  include RocketJob::Plugins::Batch
  include RocketJob::Plugins::Batch::Tabular::Input

  self.destroy_on_complete = false

  def perform(record)
    record
  end
end
