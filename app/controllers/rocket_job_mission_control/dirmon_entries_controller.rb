module RocketJobMissionControl
  class DirmonEntriesController < RocketJobMissionControl::ApplicationController
    before_filter :find_job, except: [:index, :new, :edit, :update]
    before_filter :load_jobs, only:  [:index, :show, :new, :edit]
    before_filter :check_for_cancel, :only => [:create, :update]

    def index

    end

    def show

    end

    def new
      @dirmon_entry = RocketJob::DirmonEntry.new
    end

    def create
      hash = JSON.parse(params[:dirmon_entries][:arguments])
      params[:dirmon_entries][:arguments] = []
      params[:dirmon_entries][:arguments] << hash

      @dirmon_entry = RocketJob::DirmonEntry.new(params[:dirmon_entries])
      if @dirmon_entry.save
        flash[:alert] = "success"
        redirect_to(dirmon_entries_path)
      else
        redirect_to(new_dirmon_entry_path)
      end
    end

    def destroy
      @dirmon_entry.destroy
      redirect_to(dirmon_entries_path)
    end

    def edit
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])
    end

    def update
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])

      if @dirmon_entry.update_attributes(params[:rocket_job_dirmon_entry])
        redirect_to dirmon_entries_path
      else
        render 'new'
      end
    end

    def enable
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])

      if  @dirmon_entry.update_attributes(enabled: true)
        redirect_to "/rocketjob/dirmon_entries/#{@dirmon_entry.id}"
      else
        raise "error enabling dirmon"
      end
    end

    def disable
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])

      if  @dirmon_entry.update_attributes(enabled: false)
        redirect_to "/rocketjob/dirmon_entries/#{@dirmon_entry.id}"
      else
        raise "error disabling dirmon"
      end
    end


    private

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
