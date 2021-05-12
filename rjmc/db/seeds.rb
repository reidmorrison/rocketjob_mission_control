# Create sample jobs in the various states.
# Loaded with the rake db:seed
#
# Note: Assumes Rocket Job servers/workers are not active.
#
# Scheduled Jobs
RocketJob::Jobs::SimpleJob.create!(run_at: 1.year.from_now)

# Queued Jobs
RocketJob::Jobs::SimpleJob.create!
AllTypesJob.create!(string: "Hello World")

# Paused Jobs
RocketJob::Jobs::SimpleJob.new.pause!

# Failed Jobs
RocketJob::Jobs::SimpleJob.new.fail!("Oh no", "TestWorker")

# Aborted Jobs
RocketJob::Jobs::SimpleJob.new.abort!

# Running Jobs with varying priority

RocketJob::Jobs::SimpleJob.new(priority: 50).start!
RocketJob::Jobs::SimpleJob.new(priority: 60).start!
RocketJob::Jobs::SimpleJob.new(priority: 10).start!
RocketJob::Jobs::SimpleJob.new(priority: 90).start!

# KaboomBatchJob with exceptions.
count = 100
job   = KaboomBatchJob.new
job.input_category.slice_size = 1
job.upload do |stream|
  count.times { |i| stream << "Slice number #{i}" }
end
# Manually run job to get some failures without needing workers.
while job.input.queued.count.positive?
  begin
    job.perform_now
  rescue StandardError
    # perform_now re-raises exceptions.
  end
end
job.save!

# Running Jobs
job = CSVJob.new
job.input_category.slice_size = 1
job.upload do |stream|
  # Write header row.
  stream << "name,age,state"

  # Write 10 lines.
  10.times { |i| stream << "jack,#{i + 20},FL" }
end
job.perform_now
job.save!
