module RocketJobMissionControl
  class DirmonEntriesController < RocketJobMissionControl::ApplicationController
    before_filter :find_entry_or_redirect, except: [:index, :new, :create]
    before_filter :clean_values, only: [:create, :update]
    before_action :load_entries, only: [:index, :show, :new, :edit]

    def index
    end

    def show
    end

    def new
      @dirmon_entry = RocketJob::DirmonEntry.new(arguments: nil)
    end

    def create
      @dirmon_entry = RocketJob::DirmonEntry.new(params[:rocket_job_dirmon_entry])

      if @dirmon_entry.save
        flash[:success] = t(:success, scope: [:dirmon_entry, :create])
        redirect_to(dirmon_entry_path(@dirmon_entry))
      else
        load_entries
        render :new
      end
    end

    def destroy
      @dirmon_entry.destroy
      flash[:success] = t(:success, scope: [:dirmon_entry, :destroy])

      redirect_to(dirmon_entries_path)
    end

    def edit
    end

    def update
      if @dirmon_entry.update_attributes(params[:rocket_job_dirmon_entry])
        flash[:success] = t(:success, scope: [:dirmon_entry, :update])
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        load_entries
        render :edit
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
      arguments       = params[:rocket_job_dirmon_entry][:arguments]
      if arguments.present?
        #FIXME: Rescue parse errors and return to user.
        arguments = JSON.parse(arguments)
        params[:rocket_job_dirmon_entry][:arguments] = arguments.kind_of?(Array) ? arguments : [arguments]
      end
    end

    def load_entries
      @states  = dirmons_params
      @state   = @states.include?('enabled')
      @dirmons = RocketJob::DirmonEntry.limit(1000).sort(created_at: :desc)
      @dirmons = @dirmons.where(enabled: @state) unless @states.empty? || @states.size == 2
    end

    def find_entry_or_redirect
      @dirmon_entry = RocketJob::DirmonEntry.find(params[:id])

      if @dirmon_entry.nil?
        flash[:alert] = t(:failure, scope: [:dirmon_entry, :find], id: params[:id])

        redirect_to(dirmon_entries_path)
      end
    end

    def dirmons_params
      params.fetch(:states, [])
    end

    def dirmon_params
      params.require(:dirmon_entry).permit(:name, :archive_directory, {arguments: []}, :pattern, {properties: []}, :enabled, :job_class_name)
    end

  end
end
