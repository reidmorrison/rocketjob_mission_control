module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    if Rails.version.to_i < 5
      before_filter :find_job_or_redirect, except: %i[index aborted completed failed paused queued running scheduled]
      before_filter :authorize_read, only: %i[index running paused completed aborted failed queued scheduled]
      before_filter :show_sidebar
    else
      before_action :find_job_or_redirect, except: %i[index aborted completed failed paused queued running scheduled]
      before_action :authorize_read, only: %i[index running paused completed aborted failed queued scheduled]
      before_action :show_sidebar
    end

    rescue_from StandardError, with: :error_occurred

    def index
      jobs            = RocketJob::Job.all.only(JobsDatatable::ALL_FIELDS)
      @data_table_url = jobs_url(format: 'json')

      render_datatable(jobs, 'All', JobsDatatable::ALL_COLUMNS, id: :desc)
    end

    def running
      # Prevent throttled jobs from displaying.
      jobs            = RocketJob::Job.
        running.
        where(:started_at.lte => (Time.now - 0.1)).
        only(JobsDatatable::RUNNING_FIELDS)
      @data_table_url = running_jobs_url(format: 'json')

      render_datatable(jobs, 'Running', JobsDatatable::RUNNING_COLUMNS, priority: :asc, created_at: :asc)
    end

    def paused
      jobs            = RocketJob::Job.paused.only(JobsDatatable::COMMON_FIELDS)
      @data_table_url = paused_jobs_url(format: 'json')

      render_datatable(jobs, 'Paused', JobsDatatable::PAUSED_COLUMNS, completed_at: :desc)
    end

    def completed
      jobs            = RocketJob::Job.completed.only(JobsDatatable::COMMON_FIELDS)
      @data_table_url = completed_jobs_url(format: 'json')

      render_datatable(jobs, 'Completed', JobsDatatable::COMPLETED_COLUMNS, completed_at: :desc)
    end

    def aborted
      jobs            = RocketJob::Job.aborted.only(JobsDatatable::COMMON_FIELDS)
      @data_table_url = aborted_jobs_url(format: 'json')

      render_datatable(jobs, 'Aborted', JobsDatatable::ABORTED_COLUMNS, completed_at: :desc)
    end

    def failed
      jobs            = RocketJob::Job.failed.only(JobsDatatable::COMMON_FIELDS)
      @data_table_url = failed_jobs_url(format: 'json')

      render_datatable(jobs, 'Failed', JobsDatatable::FAILED_COLUMNS, completed_at: :desc)
    end

    def queued
      jobs            = RocketJob::Job.queued_now.only(JobsDatatable::QUEUED_FIELDS)
      @data_table_url = queued_jobs_url(format: 'json')

      render_datatable(jobs, 'Queued', JobsDatatable::QUEUED_COLUMNS, priority: :asc, created_at: :asc)
    end

    def scheduled
      jobs            = RocketJob::Job.scheduled.only(JobsDatatable::SCHEDULED_FIELDS)
      @data_table_url = scheduled_jobs_url(format: 'json')

      render_datatable(jobs, 'Scheduled', JobsDatatable::SCHEDULED_COLUMNS, run_at: :asc)
    end

    def update
      authorize! :update, @job
      permitted_params = JobSanitizer.sanitize(params[:job], @job.class, @job)
      if @job.errors.empty? && @job.valid? && @job.update_attributes(permitted_params)
        redirect_to job_path(@job)
      else
        render :edit
      end
    end

    def abort
      authorize! :abort, @job
      @job.abort!
      redirect_to(job_path(@job))
    end

    def destroy
      authorize! :destroy, @job
      @job.destroy
      redirect_to(jobs_path)
    end

    def retry
      authorize! :retry, @job
      @job.retry!
      redirect_to(job_path(@job))
    end

    def pause
      authorize! :pause, @job
      @job.pause!
      redirect_to(job_path(@job))
    end

    def resume
      authorize! :resume, @job
      @job.resume!
      redirect_to(job_path(@job))
    end

    def run_now
      authorize! :run_now, @job
      @job.unset(:run_at) if @job.scheduled?
      redirect_to(job_path(@job))
    end

    def fail
      authorize! :fail, @job
      @job.fail!

      redirect_to(job_path(@job))
    end

    def show
      authorize! :read, @job
    end

    def edit
      authorize! :edit, @job
    end

    def edit_record
      error_type = params[:error_type]
      @offset    = params.fetch(:offset, 0).to_i
      @line_index = params[:line_index].to_i

      scope           = @job.input.failed.where('exception.class_name' => error_type)
      count           = scope.count
      current_failure = scope.order(_id: 1).limit(1).skip(@offset).first

      @lines             = current_failure.records
      @failure_exception = current_failure.try!(:exception)

      @edit_input_pagination = {
        record_number: current_failure['exception']['record_number'] - 1,
        offset: @offset,
        total: (count - 1)
      }
    end

    def edit_input
      error_type = params[:error_type]
      @offset    = params.fetch(:offset, 0).to_i
      scope           = @job.input.failed.where('exception.class_name' => error_type)
      count           = scope.count
      current_failure = scope.order(_id: 1).limit(1).skip(@offset).first

      @lines             = current_failure.records
      @failure_exception = current_failure.try!(:exception)

      @edit_input_pagination = {
        record_number: current_failure['exception']['record_number'],
        offset: @offset,
        total: (count - 1)
      }
    end

    def update_input
      error_type      = params[:error_type]
      offset          = params[:offset]
      updated_records = params['job']['records']

      slice         = @job.input.failed.skip(offset).first

      # removes line
      slice.records = updated_records.reject(&:empty?)

      if slice.save!
        redirect_to edit_input_job_path(@job, error_type: error_type)
        flash[:success] = 'sliced updated'
      else
        raise 'oooooppppsssss'
      end
    end

    def exception
      authorize! :read, @job
      error_type = params[:error_type]
      offset     = params.fetch(:offset, 0).to_i

      unless error_type.present?
        flash[:notice] = t(:no_errors, scope: %i[job failures])
        redirect_to(job_path(@job))
      end

      scope = @job.input.failed.where('exception.class_name' => error_type)
      count = scope.count
      unless count > 0
        flash[:notice] = t(:no_errors, scope: %i[job failures])
        redirect_to(job_path(@job))
      end

      current_failure    = scope.order(_id: 1).limit(1).skip(offset).first
      @failure_exception = current_failure.try!(:exception)

      @pagination = {
        offset: offset,
        total:  (count - 1)
      }
    end

    private

    def authorize_read
      authorize! :read, RocketJob::Job
    end

    def show_sidebar
      @jobs_sidebar = true
    end

    def find_job_or_redirect
      unless @job = RocketJob::Job.where(id: params[:id]).first
        flash[:alert] = t(:failure, scope: %i[job find], id: params[:id])

        redirect_to(jobs_path)
      end
    end

    def job_params
      params.require(:job).permit(@job.class.user_editable_fields)
    end

    def error_occurred(exception)
      if defined?(SemanticLogger::Logger) && logger.is_a?(SemanticLogger::Logger)
        logger.error 'Error loading a job', exception
      else
        logger.error "Error loading a job. #{exception.class}: #{exception.message}\n#{(exception.backtrace || []).join("\n")}"
      end

      flash[:danger] = if exception.is_a?(AccessGranted::AccessDenied)
                         'Access not authorized.'
                       else
                         'Error loading jobs.'
                       end

      raise exception if Rails.env.development? || Rails.env.test?
      redirect_to :back
    end

    def render_datatable(jobs, description, columns, sort_order)
      respond_to do |format|
        format.html do
          @description  = description
          @columns      = columns
          @table_layout = build_table_layout(columns)
          render :index
        end
        format.json do
          query                 = RocketJobMissionControl::Query.new(jobs, sort_order)
          query.search_columns  = %i[_type description]
          query.display_columns = columns.collect { |c| c[:field] }.compact
          render(json: JobsDatatable.new(view_context, query, columns))
        end
      end
    end

    def build_table_layout(columns)
      index = 0
      columns.collect do |column|
        h             = {data: index.to_s}
        h[:width]     = column[:width] if column.key?(:width)
        h[:orderable] = column[:orderable] if column.key?(:orderable)
        index         += 1
        h
      end
    end
  end
end
