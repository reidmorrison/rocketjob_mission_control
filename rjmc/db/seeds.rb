# Create sample data so that every RocketJob Mission Control view can be
# exercised without a running Rocket Job cluster.
#
# Loaded with `bin/rake db:seed`. Safe to run repeatedly, each run adds more
# data. Assumes Rocket Job servers/workers are not active.
#
# Covers:
#   - Jobs in every state: scheduled, queued, running, paused, failed, aborted, completed
#   - Regular jobs, batch jobs, cron scheduled jobs, and jobs with user editable fields
#   - Batch jobs with slices, collected output, and failed slice exceptions
#   - Servers in various states (populates the Servers view)
#   - Active workers (populates the Active Workers view)
#   - Dirmon entries in every state: pending, enabled, disabled, failed

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Force a job into the running state and pin it to a worker so that it shows up
# in both the running jobs view and the active workers view.
def pretend_running!(job, worker_name)
  job.start
  job.worker_name = worker_name
  job.started_at  = rand(1..90).minutes.ago
  job.save!
  job
end

# Fail a job with a realistic looking exception, including a backtrace.
def fail_with_exception!(job, exception_class, message, worker_name)
  exception = begin
    raise exception_class, message
  rescue exception_class => e
    e
  end
  job.start
  job.worker_name = worker_name
  job.fail!(worker_name, exception)
  job
end

WORKERS = [
  "batch-server-01:34521:worker-001",
  "batch-server-01:34521:worker-002",
  "batch-server-02:51002:worker-001",
  "web-server-03:22981:worker-001"
].freeze

# ---------------------------------------------------------------------------
# Scheduled jobs (run_at in the future, and cron scheduled jobs)
# ---------------------------------------------------------------------------

RocketJob::Jobs::SimpleJob.create!(run_at: 1.hour.from_now, description: "Warm the cache", priority: 55)
RocketJob::Jobs::SimpleJob.create!(run_at: 1.day.from_now, description: "Nightly reconciliation", priority: 20)
RocketJob::Jobs::SimpleJob.create!(run_at: 1.year.from_now, description: "Annual archive", priority: 70)

# Cron scheduled jobs.
ReportJob.create!(report_type: "daily", recipients: %w[ops@example.com finance@example.com])
ReportJob.create!(report_type: "weekly", cron_schedule: "0 7 * * 1 America/New_York", priority: 25)
RocketJob::Jobs::HousekeepingJob.create!

# ---------------------------------------------------------------------------
# Queued jobs (a variety of types and priorities)
# ---------------------------------------------------------------------------

RocketJob::Jobs::SimpleJob.create!
AllTypesJob.create!(
  string:        "Hello World",
  string_values: "three",
  integer:       42,
  float:         3.14,
  boolean:       true,
  symbol:        :ready,
  array:         %w[alpha beta gamma],
  hash_field:    {"nested" => {"key" => "value"}, "count" => 3}
)
EmailBlastJob.create!(
  subject:    "Summer Sale",
  body:       "Everything must go!",
  segment:    "active",
  recipients: %w[alice@example.com bob@example.com],
  priority:   35
)
EmailBlastJob.create!(subject: "Win-back campaign", segment: "lapsed", priority: 65)
RocketJob::Jobs::OnDemandJob.create!(
  description: "One off data cleanup",
  code:        "RocketJob.logger.info 'Running on demand cleanup'"
)

# ---------------------------------------------------------------------------
# Paused jobs
# ---------------------------------------------------------------------------

RocketJob::Jobs::SimpleJob.new(description: "Paused for maintenance").pause!
EmailBlastJob.new(subject: "Paused blast", segment: "vip").pause!

# ---------------------------------------------------------------------------
# Failed jobs (various exception types with backtraces)
# ---------------------------------------------------------------------------

fail_with_exception!(RocketJob::Jobs::SimpleJob.new(description: "Downstream API call"),
                     RuntimeError, "Connection refused - connect(2) for api.example.com:443", WORKERS[0])
fail_with_exception!(AllTypesJob.new(string: "boom", string_values: "one"),
                     ArgumentError, "Invalid argument: expected Integer, got String", WORKERS[1])
fail_with_exception!(EmailBlastJob.new(subject: "Failed blast", segment: "new"),
                     StandardError, "SMTP server did not respond", WORKERS[3])

# Simple fail without a full exception object.
RocketJob::Jobs::SimpleJob.new(description: "Legacy failure").fail!("Oh no", "TestWorker")

# ---------------------------------------------------------------------------
# Aborted jobs
# ---------------------------------------------------------------------------

RocketJob::Jobs::SimpleJob.new(description: "Cancelled by operator").abort!
EmailBlastJob.new(subject: "Aborted blast", segment: "active").abort!

# ---------------------------------------------------------------------------
# Running jobs (varying priority, pinned to workers for the Active Workers view)
# ---------------------------------------------------------------------------

pretend_running!(RocketJob::Jobs::SimpleJob.new(priority: 10, description: "High priority sync"), WORKERS[0])
pretend_running!(RocketJob::Jobs::SimpleJob.new(priority: 50, description: "Normal batch"), WORKERS[1])
pretend_running!(RocketJob::Jobs::SimpleJob.new(priority: 90, description: "Low priority backfill"), WORKERS[2])
pretend_running!(EmailBlastJob.new(priority: 40, subject: "In flight blast", segment: "vip"), WORKERS[3])

# ---------------------------------------------------------------------------
# Batch jobs
# ---------------------------------------------------------------------------

# Completed batch job with collected output (destroy_on_complete = false).
import = DataImportJob.new(region: "us-west")
import.input_category.slice_size = 3
import.output_category.columns   = %w[name age state]
import.upload do |stream|
  stream << "name,age,state"
  %w[alice bob carol dave erin frank grace].each_with_index do |name, i|
    stream << "#{name},#{20 + i},ca"
  end
end
import.perform_now
import.save!

# Completed CSV batch job.
csv = CSVJob.new
csv.input_category.slice_size = 1
csv.upload do |stream|
  stream << "name,age,state"
  10.times { |i| stream << "jack,#{i + 20},FL" }
end
csv.perform_now
csv.save!

# Batch job left with failed slices and exceptions (KaboomBatchJob raises on
# every record). Manually processed so no workers are required.
kaboom = KaboomBatchJob.new
kaboom.input_category.serializer = :none
kaboom.input_category.slice_size = 10
kaboom.upload do |stream|
  100.times { |i| stream << "Line number #{i + 1}" }
end
while kaboom.running? || kaboom.queued?
  begin
    kaboom.perform_now
  rescue StandardError
    # perform_now re-raises exceptions; ignore so remaining slices process.
  end
end
kaboom.save!

# Queued batch job (uploaded but not started) so the batch input slices view has
# pending work to show.
pending_batch = CSVJob.new(description: "Awaiting workers")
pending_batch.input_category.slice_size = 5
pending_batch.upload do |stream|
  stream << "name,age,state"
  25.times { |i| stream << "pat,#{30 + i},NY" }
end
pending_batch.save!

# Partially completed running batch job, to exercise the slice progress bar on
# the job details view. record_count is set during upload (before the job runs),
# so the bar can show real progress. There are no workers, so simulate progress
# by hand: 100 records at a slice_size of 10 uploads 10 slices. Rocket Job
# deletes each input slice as it completes, so completed slices are inferred
# from record_count. Delete six to represent completed work, mark one active and
# one failed, and leave two queued (Completed 6, Active 1, Failed 1, Queued 2).
partial_batch = CSVJob.new(description: "Partially processed import")
partial_batch.input_category.slice_size = 10
partial_batch.upload do |stream|
  stream << "name,age,state"
  100.times { |i| stream << "sam,#{20 + i},TX" }
end
pretend_running!(partial_batch, WORKERS[0])

# Six completed slices: Rocket Job removes input slices once they finish.
partial_batch.input.queued.limit(6).to_a.each(&:destroy)

# One active slice, running on a worker.
active_slice             = partial_batch.input.queued.first
active_slice.worker_name = WORKERS[0]
active_slice.start!

# One failed slice, with an exception explaining why.
slice_exception = begin
  raise ArgumentError, "Invalid state code for record: 'ZZ'"
rescue ArgumentError => e
  e
end
failed_slice             = partial_batch.input.queued.first
failed_slice.worker_name = WORKERS[1]
failed_slice.start
failed_slice.fail!(slice_exception)

# ---------------------------------------------------------------------------
# Servers (populates the Servers view)
# ---------------------------------------------------------------------------

def build_heartbeat(workers)
  RocketJob::Heartbeat.new(updated_at: Time.now, workers: workers)
end

RocketJob::Server.create!(
  name:        "batch-server-01:34521",
  max_workers: 10,
  started_at:  3.hours.ago,
  state:       :running,
  heartbeat:   build_heartbeat(8)
)
RocketJob::Server.create!(
  name:        "batch-server-02:51002",
  max_workers: 10,
  started_at:  90.minutes.ago,
  state:       :running,
  heartbeat:   build_heartbeat(4)
)
RocketJob::Server.create!(
  name:        "web-server-03:22981",
  max_workers: 5,
  started_at:  20.minutes.ago,
  state:       :paused,
  heartbeat:   build_heartbeat(0)
)
RocketJob::Server.create!(
  name:        "batch-server-04:19222",
  max_workers: 10,
  started_at:  5.minutes.ago,
  state:       :starting,
  heartbeat:   build_heartbeat(0)
)
RocketJob::Server.create!(
  name:        "batch-server-05:44100",
  max_workers: 10,
  started_at:  4.hours.ago,
  state:       :stopping,
  heartbeat:   build_heartbeat(2)
)
# A zombie server whose heartbeat has gone stale.
RocketJob::Server.create!(
  name:        "batch-server-06:60333",
  max_workers: 10,
  started_at:  1.day.ago,
  state:       :running,
  heartbeat:   RocketJob::Heartbeat.new(updated_at: 1.hour.ago, workers: 10)
)

# ---------------------------------------------------------------------------
# Dirmon entries (populates the Dirmon Entries view, one per state)
# ---------------------------------------------------------------------------

# Pending (default state on create).
RocketJob::DirmonEntry.create!(
  name:              "Import customers",
  pattern:           "input_files/customers/*.csv",
  job_class_name:    "DataImportJob",
  archive_directory: "archive/customers",
  properties:        {"description" => "Imported via Dirmon", "priority" => 45}
)

# Enabled.
enabled = RocketJob::DirmonEntry.new(
  name:              "Process orders",
  pattern:           "input_files/orders/*.{csv,txt}",
  job_class_name:    "CSVJob",
  archive_directory: "archive/orders",
  properties:        {"priority" => 30}
)
enabled.enable!

# Disabled.
disabled = RocketJob::DirmonEntry.new(
  name:              "Legacy feed (paused)",
  pattern:           "input_files/legacy/**/*",
  job_class_name:    "CSVJob",
  archive_directory: "archive/legacy"
)
disabled.enable!
disabled.disable!

# Failed, with an exception explaining why.
failed = RocketJob::DirmonEntry.new(
  name:              "Restricted uploads",
  pattern:           "/etc/*.conf",
  job_class_name:    "CSVJob",
  archive_directory: "archive/restricted"
)
failed.enable!
failed.fail!("dirmon-worker:1234", "Security violation: pattern is not in the whitelist_paths")

puts "Seed data created."
puts "  Jobs:           #{RocketJob::Job.count}"
puts "  Servers:        #{RocketJob::Server.count}"
puts "  Dirmon entries: #{RocketJob::DirmonEntry.count}"
