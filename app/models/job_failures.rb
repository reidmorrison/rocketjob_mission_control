class JobFailures
  attr_reader :job_id

  def initialize(job_id)
    @job_id = job_id
  end

  def job
    @job ||= RocketJob::Job.find(job_id)
  end

  def list
    @slice_errors ||= job.input.group_exceptions
  end

  def for_error(error_type, page_offset=0)
    query = {'exception.class_name' => error_type}
    job.input.failed.where(query).limit(1).skip(page_offset).first
  end
end
