module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    before_filter :find_server, only: [:stop, :pause, :resume, :destroy]
    before_filter :show_sidebar

    def index
      @servers        = RocketJob::Server.all
      @description    = 'All'
      @data_table_url = servers_url(format: 'json')
      @actions        = [:pause_all, :resume_all, :stop_all, :destroy_zombies]
      respond_with_query
    end

    def starting
      @servers        = RocketJob::Server.starting
      @description    = 'Starting'
      @data_table_url = starting_servers_url(format: 'json')
      @actions        = [:pause_all, :stop_all]
      respond_with_query
    end

    def running
      @servers        = RocketJob::Server.running
      @description    = 'Running'
      @data_table_url = running_servers_url(format: 'json')
      @actions        = [:pause_all, :stop_all, :destroy_zombies]
      respond_with_query
    end

    def paused
      @servers        = RocketJob::Server.paused
      @description    = 'Paused'
      @data_table_url = paused_servers_url(format: 'json')
      @actions        = [:resume_all, :destroy_zombies]
      respond_with_query
    end

    def stopping
      @servers        = RocketJob::Server.stopping
      @description    = 'Stopping'
      @data_table_url = stopping_servers_url(format: 'json')
      @actions        = [:destroy_zombies]
      respond_with_query
    end

    def zombie
      @servers        = RocketJob::Server.zombies
      @description    = 'Zombie'
      @data_table_url = zombie_servers_url(format: 'json')
      @actions        = [:destroy_zombies]
      respond_with_query
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

    def respond_with_query
      @query = RocketJobMissionControl::Query.new(@servers, name: :asc)
      respond_to do |format|
        format.html do
          @server_counts = RocketJob::Server.counts_by_state
          # TODO: Move into RocketJob
          @server_counts[:zombie] = RocketJob::Server.zombies.count
          render :index
        end
        format.json { render(json: ServersDatatable.new(view_context, @query)) }
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
