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
      @dirmon_entry = RocketJob::DirmonEntry.new(dirmon_params)

      parse_and_assign_arguments

      if @dirmon_entry.errors.empty? && @dirmon_entry.save
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
      parse_and_assign_arguments
      if @dirmon_entry.errors.empty? && @dirmon_entry.update_attributes(dirmon_params)
        flash[:success] = t(:success, scope: [:dirmon_entry, :update])
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        load_entries
        render :edit
      end
    end

    def enable
      if @dirmon_entry.may_enable?
        @dirmon_entry.enable!
        flash[:success] = t(:success, scope: [:dirmon_entry, :enable])
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        flash[:alert]  = t(:failure, scope: [:dirmon_entry, :enable])
        load_entries
        render(:show)
      end
    end

    def disable
      if @dirmon_entry.may_disable?
        @dirmon_entry.disable!
        flash[:success] = t(:success, scope: [:dirmon_entry, :disable])
        redirect_to(rocket_job_mission_control.dirmon_entry_path(@dirmon_entry))
      else
        flash[:alert]  = t(:failure, scope: [:dirmon_entry, :disable])
        load_entries
        render(:show)
      end
    end

    private

    def parse_and_assign_arguments
      if arguments = params[:rocket_job_dirmon_entry][:arguments]
        begin
          arguments               = JSON.parse(arguments)
          @dirmon_entry.arguments = arguments.kind_of?(Array) ? arguments : [arguments]
        rescue JSON::ParserError => e
          @dirmon_entry.errors.add(:arguments, e.message)
        end
      end

    end

    def clean_values
      params[:rocket_job_dirmon_entry].fetch(:properties, {}).each_pair do |param, value|
        params[:rocket_job_dirmon_entry][:properties].delete(param) if value.blank?
      end
    end

    def load_entries
      @states  = dirmons_params
      @dirmons = RocketJob::DirmonEntry.limit(1000).sort(created_at: :desc)
      @dirmons = @dirmons.where(state: @states) unless @states.empty?
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
      params
        .require(:rocket_job_dirmon_entry)
        .permit(:name, :archive_directory, :pattern, :job_class_name, :perform_method).tap do |whitelist|
        whitelist[:properties] = params[:rocket_job_dirmon_entry][:properties] if params[:rocket_job_dirmon_entry][:properties]
      end
    end

  end
end
