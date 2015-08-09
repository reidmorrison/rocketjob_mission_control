module RocketJobMissionControl
  class DirmonEntriesController < RocketJobMissionControl::ApplicationController
    before_filter :find_job
    before_filter :check_for_cancel, :only => [:create, :update]
    before_filter :clean_values, :only => [:create, :update]

    def index
      load_jobs
    end

    def show
      load_jobs
    end

    def new
      load_jobs
      @dirmon_entry = RocketJob::DirmonEntry.new
    end

    def create
      @dirmon_entry = RocketJob::DirmonEntry.new(params[:rocket_job_dirmon_entry])
      if @dirmon_entry.save
        flash[:success] = t(:success, scope: [:dirmon_entry, :create])
        redirect_to(dirmon_entries_path)
      else
        redirect_to(new_dirmon_entry_path)
      end
    end

    def destroy
      if @dirmon_entry.destroy
        flash[:success] = t(:success, scope: [:dirmon_entry, :destroy])
        redirect_to(dirmon_entries_path)
      else
        flash[:alert]  = t(:invalid, scope: [:dirmon_entry, :destroy])

      end
    end

    def edit
      load_jobs
      @dirmon_entry.arguments = pretty_print_array_or_hash(@dirmon_entry.arguments)
    end

    def update
      if @dirmon_entry.update_attributes(params[:rocket_job_dirmon_entry])
        flash[:success] = t(:success, scope: [:dirmon_entry, :update])
        redirect_to dirmon_entries_path
      else
        flash[:alert]  = t(:invalid, scope: [:dirmon_entry, :update])
      end
    end

    def enable
      if  @dirmon_entry.update_attributes(enabled: true)
        flash[:success] = t(:success, scope: [:dirmon_entry, :enable])
        redirect_to "/rocketjob/dirmon_entries/#{@dirmon_entry.id}"
      else
        flash[:alert]  = t(:failure, scope: [:dirmon_entry, :enable])
      end
    end

    def disable
      if  @dirmon_entry.update_attributes(enabled: false)
        flash[:success] = t(:success, scope: [:dirmon_entry, :disable])
        redirect_to "/rocketjob/dirmon_entries/#{@dirmon_entry.id}"
      else
        flash[:alert]  = t(:failure, scope: [:dirmon_entry, :disable])
      end
    end

    private

    def clean_values
      locations_array = params[:rocket_job_dirmon_entry][:properties][:location_ids].split
      properties = params[:rocket_job_dirmon_entry][:properties]
      arguments = params[:rocket_job_dirmon_entry][:arguments]
      params[:rocket_job_dirmon_entry][:properties][:location_ids] = locations_array unless locations_array.empty?
      params[:rocket_job_dirmon_entry][:properties] = properties.delete_if {|key, value| value.empty?}
      if arguments.present?
        hash = JSON.parse(arguments)
        params[:rocket_job_dirmon_entry][:arguments] = []
        params[:rocket_job_dirmon_entry][:arguments] << hash
      else
        params[:rocket_job_dirmon_entry][:arguments] = []
      end
    end

    def pretty_print_array_or_hash(arguments)
      return arguments unless arguments.kind_of?(Array) || arguments.kind_of?(Hash)
      json_string_options = { }
      JSON.generate(arguments, json_string_options).gsub(/\[|\]/, '').html_safe
    end

    def check_for_cancel
      if params[:commit] == "Cancel"
        redirect_to dirmon_entries_path
      end
    end

    def load_jobs
      @states  = dirmons_params
      @state   = @states.include?('enabled')
      @dirmons = RocketJob::DirmonEntry.limit(1000).sort(created_at: :desc)
      @dirmons = @dirmons.where(enabled: @state) unless @states.empty? || @states.size == 2
    end

    def find_job
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])
    end

    def dirmons_params
      params.fetch(:states, [])
    end

    def dirmon_params
      params.require(:dirmon_entry).permit(:name, :archive_directory, :arguments, :path, :properties, :enabled, :job_name)
    end

    def error_occurred(exception)
      logger.error "Error loading a job", exception
      flash[:danger] = "Error loading jobs."
      raise exception if Rails.env.development?
      redirect_to :back
    end
  end
end
