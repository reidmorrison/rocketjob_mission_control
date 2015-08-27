module RocketJobMissionControl
  module Jobs
    class FailuresController < RocketJobMissionControl::ApplicationController
      def index
        job_failures = JobFailures.new(params[:job_id])
        @job  = job_failures.job

        if @job && @job.failed?
          @slice_errors = job_failures.list

          if @slice_errors.present?
            @error_type   = params[:error_type] || @slice_errors.first['_id']['error_class']

            offset             = params.fetch(:offset, 0).to_i
            selected_exception = job_failures.for_error(@error_type, offset)
            current_failure    = selected_exception.first

            @pagination = {
              offset: offset,
              total:  (selected_exception.count - 1),
            }

            if current_failure.present?
              @failure_exception = current_failure['exception']
            end
          else
            flash[:notice] = t(:no_errors, scope: [:job, :failures])
          end
        else
          redirect_to(job_path(params[:job_id]))
        end
      end
    end
  end
end
