module RocketJobMissionControl
  class DirmonEntriesController < RocketJobMissionControl::ApplicationController
    if Rails.version.to_i < 5
      before_filter :find_entry_or_redirect, except: %i[index disabled enabled failed pending new create]
      before_filter :authorize_read, only: %i[index disabled enabled failed pending]
      before_filter :show_sidebar
    else
      before_action :find_entry_or_redirect, except: %i[index disabled enabled failed pending new create]
      before_action :authorize_read, only: %i[index disabled enabled failed pending]
      before_action :show_sidebar
    end

    rescue_from AccessGranted::AccessDenied do |exception|
      raise exception if Rails.env.development? || Rails.env.test?

      redirect_to :back, alert: "Access not authorized."
    end

    def index
      @data_table_url = dirmon_entries_url(format: "json")
      render_datatable(RocketJob::DirmonEntry.all, "All")
    end

    def disabled
      @data_table_url = disabled_dirmon_entries_url(format: "json")
      render_datatable(RocketJob::DirmonEntry.disabled, "Disabled")
    end

    def enabled
      @data_table_url = enabled_dirmon_entries_url(format: "json")
      render_datatable(RocketJob::DirmonEntry.enabled, "Enabled")
    end

    def failed
      @data_table_url = failed_dirmon_entries_url(format: "json")
      render_datatable(RocketJob::DirmonEntry.failed, "Failed")
    end

    def pending
      @data_table_url = pending_dirmon_entries_url(format: "json")
      render_datatable(RocketJob::DirmonEntry.pending, "Pending")
    end

    def show
    end

    def new
      @dirmon_entry             = RocketJob::DirmonEntry.new(dirmon_params)
      @previous_job_class_names = RocketJob::DirmonEntry.distinct(:job_class_name)

      if dirmon_params[:job_class_name] && !@dirmon_entry.job_class
        @dirmon_entry.errors.add(:job_class_name, "Invalid Job Class")
      end
    end

    def create
      authorize! :create, RocketJob::DirmonEntry
      @dirmon_entry = RocketJob::DirmonEntry.new(dirmon_params)
      if properties = params[:rocket_job_dirmon_entry][:properties]
        @dirmon_entry.properties = JobSanitizer.sanitize(properties, @dirmon_entry.job_class, @dirmon_entry, false)
      end

      if @dirmon_entry.errors.empty? && @dirmon_entry.save
        redirect_to(dirmon_entry_path(@dirmon_entry))
      else
        render :new
      end
    end

    def destroy
      authorize! :destroy, @dirmon_entry
      @dirmon_entry.destroy
      redirect_to(dirmon_entries_path)
    end

    def edit
      authorize! :edit, @dirmon_entry
    end

    def update
      authorize! :update, @dirmon_entry
      if properties = params[:rocket_job_dirmon_entry][:properties]
        @dirmon_entry.properties = JobSanitizer.sanitize(properties, @dirmon_entry.job_class, @dirmon_entry, false)
      end
      if @dirmon_entry.errors.empty? && @dirmon_entry.valid? && @dirmon_entry.update_attributes(dirmon_params)
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        render :edit
      end
    end

    def enable
      authorize! :enable, @dirmon_entry
      if @dirmon_entry.may_enable?
        @dirmon_entry.enable!
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        flash[:alert] = t(:failure, scope: %i[dirmon_entry enable])
        render(:show)
      end
    end

    def disable
      authorize! :disable, @dirmon_entry
      if @dirmon_entry.may_disable?
        @dirmon_entry.disable!
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        flash[:alert] = t(:failure, scope: %i[dirmon_entry disable])
        render(:show)
      end
    end

    def properties
      @dirmon_entry = RocketJob::DirmonEntry.new(dirmon_params)
      render json: @dirmon_entry
    end

    private

    def authorize_read
      authorize! :read, RocketJob::DirmonEntry
    end

    def show_sidebar
      @dirmon_sidebar = true
    end

    def find_entry_or_redirect
      unless @dirmon_entry = RocketJob::DirmonEntry.where(id: params[:id]).first
        flash[:alert] = t(:failure, scope: %i[dirmon_entry find], id: params[:id])

        redirect_to(dirmon_entries_path)
      end
    end

    def dirmon_params
      params.
        fetch(:rocket_job_dirmon_entry, {}).
        permit(:name, :archive_directory, :pattern, :job_class_name)
    end

    def render_datatable(entries, description)
      respond_to do |format|
        format.html do
          @description = description
          render :index
        end
        format.json do
          query                 = RocketJobMissionControl::Query.new(entries, name: :asc)
          query.search_columns  = %i[job_class_name name pattern]
          query.display_columns = %w[name _type pattern]
          render(json: DirmonEntriesDatatable.new(view_context, query))
        end
      end
    end
  end
end
