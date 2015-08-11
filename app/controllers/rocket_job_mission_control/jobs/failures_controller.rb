module RocketJobMissionControl
  module Jobs
    class FailuresController < RocketJobMissionControl::ApplicationController
      def index
        @job  = RocketJob::Job.find(params[:job_id])

        if @job && @job.failed?
          @slice_errors =  @job.input.collection.aggregate(
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

          @error_type = params[:error_type] || @slice_errors.first['_id']['error_class']

          query  = { 'state' => 'failed', 'exception.class_name' => @error_type }
          offset = params.fetch(:offset, 1).to_i
          selected_exception = @job.input.collection.find(query).limit(1).skip(offset)

          current_failure    = selected_exception.first

          @pagination = {
            offset: offset,
            total:  (selected_exception.count - 1),
          }

          if current_failure.present?
            @failure_exception = current_failure['exception']
          end

        else
          redirect_to(job_path(params[:job_id]))
        end
      end
    end
  end
end
