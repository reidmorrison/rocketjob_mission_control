module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    before_filter :find_server, only: [:stop, :pause, :resume, :destroy]
    before_filter :show_sidebar

    def index
      @data_table_url = servers_url(format: 'json')
      @actions        = [:pause_all, :resume_all, :stop_all, :destroy_zombies]
      render_datatable(RocketJob::Server.all, 'All')
    end

    def starting
      @data_table_url = starting_servers_url(format: 'json')
      @actions        = [:pause_all, :stop_all]
      render_datatable(RocketJob::Server.starting, 'Starting')
    end

    def running
      @data_table_url = running_servers_url(format: 'json')
      @actions        = [:pause_all, :stop_all, :destroy_zombies]
      render_datatable(RocketJob::Server.running, 'Running')
    end

    def paused
      @data_table_url = paused_servers_url(format: 'json')
      @actions        = [:resume_all, :destroy_zombies]
      render_datatable(RocketJob::Server.paused, 'Paused')
    end

    def stopping
      @data_table_url = stopping_servers_url(format: 'json')
      @actions        = [:destroy_zombies]
      render_datatable(RocketJob::Server.stopping, 'Stopping')
    end

    def zombie
      @data_table_url = zombie_servers_url(format: 'json')
      @actions        = [:destroy_zombies]
      render_datatable(RocketJob::Server.zombies, 'Zombie')
    end

    VALID_ACTIONS = [:stop_all, :pause_all, :resume_all, :destroy_zombies]

    def update_all
      server_action = params[:server_action].to_sym
      if VALID_ACTIONS.include?(server_action)
        RocketJob::Server.public_send(server_action.to_sym)
      end

      # TODO: Refresh the same page it was on
      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def stop
      @server.try!(:stop!)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      @server.try!(:destroy)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      @server.try!(:pause!)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      @server.try!(:resume!)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    private

    def render_datatable(servers, description)

      respond_to do |format|
        format.html do
          @description = description
          @states      = RocketJob::Server.aasm.states.map { |s| s.name.to_s }
          @states << 'zombie'

          @server_counts          = RocketJob::Server.counts_by_state
          # TODO: Move into RocketJob
          @server_counts[:zombie] = RocketJob::Server.zombies.count
          render :index
        end
        format.json do
          query = RocketJobMissionControl::Query.new(servers, name: :asc)
          render(json: ServersDatatable.new(view_context, query))
        end
      end
    end

    def find_server
      @server = RocketJob::Server.find(params[:id])
    end

    def show_sidebar
      @servers_sidebar = true
    end
  end
end
