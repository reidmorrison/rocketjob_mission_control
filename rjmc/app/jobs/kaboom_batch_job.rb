# Create a test job that fails with different errors for RJMC testing:
#
# count = 100
# job   = KaboomBatchJob.new(slice_size: 1)
# job.upload do |stream|
#   count.times { |i| stream << "Slice number #{i}" }
# end
# job.save!
class KaboomBatchJob < RocketJob::Job
  include RocketJob::Batch

  self.destroy_on_complete = false

  def perform(record)
    if rocket_job_record_number % 2 == 0
      raise "Blowing up on record: #{rocket_job_record_number}"
    else
      raise ArgumentError, "Blowing up on record: #{rocket_job_record_number}"
    end
  end
end
