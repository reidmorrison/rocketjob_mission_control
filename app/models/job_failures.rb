class JobFailures
  attr_reader :job_id

  def initialize(job_id)
    @job_id = job_id
  end

  def job
    @job ||= RocketJob::Job.find(job_id)
  end

  def list
    @slice_errors ||= job.input.collection.aggregate(
      [
        {
          '$group' => {
            _id:      { error_class: '$exception.class_name' },
            messages: { '$addToSet' => '$exception.message' },
            count:    { '$sum' => 1 }
          },
        }
      ]
    )
  end

  def for_error(error_type, page_offset=0)
    query  = { 'state' => 'failed', 'exception.class_name' => error_type }
    @job.input.collection.find(query).limit(1).skip(page_offset)
  end
end
