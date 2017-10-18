module RocketJobMissionControl
  class JobsController < RocketJobMissionControl::ApplicationController
    if Rails.version.to_i < 5
      before_filter :find_job_or_redirect, except: [:index, :aborted, :completed, :failed, :paused, :queued, :running, :scheduled]
      before_filter :show_sidebar
    else
      before_action :find_job_or_redirect, except: [:index, :aborted, :completed, :failed, :paused, :queued, :running, :scheduled]
      before_action :show_sidebar
    end
    rescue_from StandardError, with: :error_occurred

    def index
      jobs            = RocketJob::Job.all.only(JobsDatatable::ALL_FIELDS)
      @data_table_url = jobs_url(format: 'json')

      render_datatable(jobs, 'All', JobsDatatable::ALL_COLUMNS, id: :desc)
    end

    def running
      jobs            = RocketJob::Job.running.only(JobsDatatable::RUNNING_FIELDS)
      @data_table_url = running_jobs_url(format: 'json')

      render_datatable(jobs, 'Running', JobsDatatable::RUNNING_COLUMNS, started_at: :desc)
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

      render_datatable(jobs, 'Queued', JobsDatatable::QUEUED_COLUMNS, completed_at: :desc)
    end

    def scheduled
      jobs            = RocketJob::Job.scheduled.only(JobsDatatable::SCHEDULED_FIELDS)
      @data_table_url = scheduled_jobs_url(format: 'json')

      render_datatable(jobs, 'Scheduled', JobsDatatable::SCHEDULED_COLUMNS, run_at: :asc)
    end

    def update
      permitted_params = JobSanitizer.sanitize(params[:job], @job.class, @job)
      if @job.errors.empty? && @job.valid? && @job.update_attributes(permitted_params)
        redirect_to job_path(@job)
      else
        render :edit
      end
    end

    def abort
      @job.abort!
      redirect_to(job_path(@job))
    end

    def destroy
      @job.destroy
      redirect_to(jobs_path)
    end

    def retry
      @job.retry!
      redirect_to(job_path(@job))
    end

    def pause
      @job.pause!
      redirect_to(job_path(@job))
    end

    def resume
      @job.resume!
      redirect_to(job_path(@job))
    end

    def run_now
      @job.unset(:run_at) if @job.scheduled?
      redirect_to(job_path(@job))
    end

    def fail
      @job.fail!

      redirect_to(job_path(@job))
    end

    def show
    end

    def edit
    end

    def exceptions
      @exceptions = @job.input.group_exceptions
    end

    def exception
      error_type = params[:error_type]
      offset     = params.fetch(:offset, 0).to_i

      unless error_type.present?
        flash[:notice] = t(:no_errors, scope: [:job, :failures])
        redirect_to(job_path(@job))
      end

      scope = @job.input.failed.where('exception.class_name' => error_type)
      count = scope.count
      unless count > 0
        flash[:notice] = t(:no_errors, scope: [:job, :failures])
        redirect_to(job_path(@job))
      end

      current_failure    = scope.order(_id: 1).limit(1).skip(offset).first
      @failure_exception = current_failure.try!(:exception)

      @pagination = {
        offset: offset,
        total:  (count - 1),
      }
    end

    private

    def show_sidebar
      @jobs_sidebar = true
    end

    def find_job_or_redirect
      unless @job = RocketJob::Job.where(id: params[:id]).first
        flash[:alert] = t(:failure, scope: [:job, :find], id: params[:id])

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
      flash[:danger] = 'Error loading jobs.'
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
          query.search_columns  = [:_type, :description]
          query.display_columns = columns.collect { |c| c[:field] }.compact
          render(json: JobsDatatable.new(view_context, query, columns))
        end
      end
    end

    def build_table_layout(columns)
      index = 0
      columns.collect do |column|
        h             = {data: index.to_s}
        h[:width]     = column[:width] if column.has_key?(:width)
        h[:orderable] = column[:orderable] if column.has_key?(:orderable)
        index         += 1
        h
      end
    end

  end
end
