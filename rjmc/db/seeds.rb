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

# Cron scheduled jobs enforce a unique cron_schedule across active jobs, so
# creating them a second time raises a validation error. Skip creation when a
# job with the same schedule already exists, keeping this script safe to run
# repeatedly.
def create_cron_job!(job_class, **attributes)
  cron_schedule = attributes.fetch(:cron_schedule, job_class.cron_schedule)
  return if job_class.where(cron_schedule: cron_schedule).exists?

  job_class.create!(**attributes)
end

# ---------------------------------------------------------------------------
# Scheduled jobs (run_at in the future, and cron scheduled jobs)
# ---------------------------------------------------------------------------

RocketJob::Jobs::SimpleJob.create!(run_at: 1.hour.from_now, description: "Warm the cache", priority: 55)
RocketJob::Jobs::SimpleJob.create!(run_at: 1.day.from_now, description: "Nightly reconciliation", priority: 20)
RocketJob::Jobs::SimpleJob.create!(run_at: 1.year.from_now, description: "Annual archive", priority: 70)

# Cron scheduled jobs.
create_cron_job!(ReportJob, report_type: "daily", recipients: %w[ops@example.com finance@example.com])
create_cron_job!(ReportJob, report_type: "weekly", cron_schedule: "0 7 * * 1 America/New_York", priority: 25)
create_cron_job!(RocketJob::Jobs::HousekeepingJob)

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
# Jobs with large Array and Hash custom fields (issue #32)
#
# Some Array/Hash fields (for example tabular_output_columns) can contain
# hundreds of entries, which swamps the job status view. These jobs exercise
# both the "large" (size > 10, collapsed) and "small" (size < 10, table)
# rendering paths for custom Array and Hash attributes.
# ---------------------------------------------------------------------------

# Large Array and Hash: over 10 entries each, so the status view should collapse
# them by default. The Hash values are themselves nested Hashes to exercise
# rendering of nested structures.
large_hash = (1..40).each_with_object({}) do |i, h|
  h["field_#{format('%02d', i)}"] = {"type" => "string", "index" => i, "nullable" => i.even?}
end
AllTypesJob.create!(
  description:   "Issue #32 - large Array (60) and Hash (40), collapsed by default",
  string:        "Wide tabular output",
  string_values: "one",
  array:         (1..60).map { |i| "column_#{format('%02d', i)}" },
  hash_field:    large_hash
)

# Small Array and Hash: fewer than 10 entries each, so the status view should
# render them as a borderless, header-less table.
AllTypesJob.create!(
  description:   "Issue #32 - small Array (4) and Hash (3), rendered as a table",
  string:        "Narrow tabular output",
  string_values: "two",
  array:         %w[first_name last_name email state],
  hash_field:    {"format" => "csv", "delimiter" => ",", "encoding" => "utf-8"}
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
while kaboom.input.queued.count.positive?
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

# ---------------------------------------------------------------------------
# Servers (populates the Servers view)
# ---------------------------------------------------------------------------

def build_heartbeat(workers)
  RocketJob::Heartbeat.new(updated_at: Time.now, workers: workers)
end

# Servers have a unique name, so skip any that already exist to keep this
# script safe to run repeatedly.
def create_server!(**attributes)
  return if RocketJob::Server.where(name: attributes[:name]).exists?

  RocketJob::Server.create!(**attributes)
end

create_server!(
  name:        "batch-server-01:34521",
  max_workers: 10,
  started_at:  3.hours.ago,
  state:       :running,
  heartbeat:   build_heartbeat(8)
)
create_server!(
  name:        "batch-server-02:51002",
  max_workers: 10,
  started_at:  90.minutes.ago,
  state:       :running,
  heartbeat:   build_heartbeat(4)
)
create_server!(
  name:        "web-server-03:22981",
  max_workers: 5,
  started_at:  20.minutes.ago,
  state:       :paused,
  heartbeat:   build_heartbeat(0)
)
create_server!(
  name:        "batch-server-04:19222",
  max_workers: 10,
  started_at:  5.minutes.ago,
  state:       :starting,
  heartbeat:   build_heartbeat(0)
)
create_server!(
  name:        "batch-server-05:44100",
  max_workers: 10,
  started_at:  4.hours.ago,
  state:       :stopping,
  heartbeat:   build_heartbeat(2)
)
# A zombie server whose heartbeat has gone stale.
create_server!(
  name:        "batch-server-06:60333",
  max_workers: 10,
  started_at:  1.day.ago,
  state:       :running,
  heartbeat:   RocketJob::Heartbeat.new(updated_at: 1.hour.ago, workers: 10)
)

# ---------------------------------------------------------------------------
# Dirmon entries (populates the Dirmon Entries view, one per state)
# ---------------------------------------------------------------------------

# Dirmon entries have a unique name and pattern, so skip any that already exist
# to keep this script safe to run repeatedly. The optional block receives the
# unsaved entry to drive it into the desired state.
def create_dirmon_entry!(**attributes)
  return if RocketJob::DirmonEntry.where(name: attributes[:name]).exists?

  entry = RocketJob::DirmonEntry.new(**attributes)
  yield entry if block_given?
  entry.save! unless entry.persisted?
  entry
end

# Pending (default state on create).
create_dirmon_entry!(
  name:              "Import customers",
  pattern:           "input_files/customers/*.csv",
  job_class_name:    "DataImportJob",
  archive_directory: "archive/customers",
  properties:        {"description" => "Imported via Dirmon", "priority" => 45}
)

# Enabled.
create_dirmon_entry!(
  name:              "Process orders",
  pattern:           "input_files/orders/*.{csv,txt}",
  job_class_name:    "CSVJob",
  archive_directory: "archive/orders",
  properties:        {"priority" => 30},
  &:enable!
)

# Disabled.
create_dirmon_entry!(
  name:              "Legacy feed (paused)",
  pattern:           "input_files/legacy/**/*",
  job_class_name:    "CSVJob",
  archive_directory: "archive/legacy"
) do |entry|
  entry.enable!
  entry.disable!
end

# Failed, with an exception explaining why.
create_dirmon_entry!(
  name:              "Restricted uploads",
  pattern:           "/etc/*.conf",
  job_class_name:    "CSVJob",
  archive_directory: "archive/restricted"
) do |entry|
  entry.enable!
  entry.fail!("dirmon-worker:1234", "Security violation: pattern is not in the whitelist_paths")
end

puts "Seed data created."
puts "  Jobs:           #{RocketJob::Job.count}"
puts "  Servers:        #{RocketJob::Server.count}"
puts "  Dirmon entries: #{RocketJob::DirmonEntry.count}"
