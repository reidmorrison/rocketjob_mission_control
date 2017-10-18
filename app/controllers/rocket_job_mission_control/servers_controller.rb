module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    if Rails.version.to_i < 5
      before_filter :find_server_or_redirect, only: [:stop, :pause, :resume, :destroy]
      before_filter :show_sidebar
    else
      before_action :find_server_or_redirect, only: [:stop, :pause, :resume, :destroy]
      before_action :show_sidebar
    end

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
      else
        flash[:alert] = t(:invalid, scope: [:server, :update_all])
      end

      # TODO: Refresh the same page it was on
      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def stop
      if @server.may_stop?
        @server.stop!
      else
        flash[:alert] = t(:failure, scope: [:server, :stop])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      @server.destroy
      flash[:notice] = t(:success, scope: [:server, :destroy])

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      if @server.may_pause?
        @server.pause!
      else
        flash[:alert] = t(:failure, scope: [:server, :pause])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      if @server.may_resume?
        @server.resume!
      else
        flash[:alert] = t(:failure, scope: [:server, :resume])
      end

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

    def find_server_or_redirect
      unless @server = RocketJob::Server.where(id: params[:id]).first
        flash[:alert] = t(:failure, scope: [:server, :find], id: params[:id])

        redirect_to(servers_path)
      end
    end

    def show_sidebar
      @servers_sidebar = true
    end
  end
end
