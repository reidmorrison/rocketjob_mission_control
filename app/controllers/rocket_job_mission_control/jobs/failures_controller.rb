module RocketJobMissionControl
  module Jobs
    class FailuresController < RocketJobMissionControl::ApplicationController
      def index
        job_failures = JobFailures.new(params[:job_id])
        if @job = job_failures.job
          @slice_errors = job_failures.list

          if @slice_errors.present?
            @error_type = params[:error_type] || @slice_errors.first.class_name

            offset             = params.fetch(:offset, 0).to_i
            count              = @slice_errors.find { |exception| exception.class_name == @error_type }.try!(:count) || 0
            current_failure    = job_failures.for_error(@error_type, offset)
            @failure_exception = current_failure.try!(:exception)

            @pagination = {
              offset: offset,
              total:  (count - 1),
            }
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
