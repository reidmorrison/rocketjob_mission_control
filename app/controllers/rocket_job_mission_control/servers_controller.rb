module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    if Rails.version.to_i < 5
      before_filter :find_server_or_redirect, only: %i[stop pause resume destroy]
      before_filter :authorize_read, only: %i[index starting running paused stopping zombie]
      before_filter :show_sidebar
    else
      before_action :find_server_or_redirect, only: %i[stop pause resume destroy]
      before_action :authorize_read, only: %i[index starting running paused stopping zombie]
      before_action :show_sidebar
    end

    rescue_from AccessGranted::AccessDenied do |exception|
      raise exception if Rails.env.development? || Rails.env.test?

      redirect_to :back, alert: "Access not authorized."
    end

    def index
      @data_table_url = servers_url(format: "json")
      @actions        = %i[pause resume stop kill destroy_zombies]
      render_datatable(RocketJob::Server.all, "All")
    end

    def starting
      @data_table_url = starting_servers_url(format: "json")
      @actions        = %i[pause stop kill]
      render_datatable(RocketJob::Server.starting, "Starting")
    end

    def running
      @data_table_url = running_servers_url(format: "json")
      @actions        = %i[pause stop kill destroy_zombies]
      render_datatable(RocketJob::Server.running, "Running")
    end

    def paused
      @data_table_url = paused_servers_url(format: "json")
      @actions        = %i[resume destroy_zombies]
      render_datatable(RocketJob::Server.paused, "Paused")
    end

    def stopping
      @data_table_url = stopping_servers_url(format: "json")
      @actions        = [:destroy_zombies]
      render_datatable(RocketJob::Server.stopping, "Stopping")
    end

    def zombie
      @data_table_url = zombie_servers_url(format: "json")
      @actions        = [:destroy_zombies]
      render_datatable(RocketJob::Server.zombies, "Zombie")
    end

    VALID_ACTIONS = %i[stop kill pause resume thread_dump].freeze

    def update_all
      server_action = params[:server_action].to_sym
      authorize! server_action, RocketJob::Server

      if server_action == :destroy_zombies
        RocketJob::Server.destroy_zombies
      elsif VALID_ACTIONS.include?(server_action)
        RocketJob::Subscribers::Server.publish(server_action)
        flash[:success] = t(:success, scope: %i[server update_all], action: server_action.to_s)
      else
        flash[:danger] = t(:invalid, scope: %i[server update_all])
      end

      # TODO: Refresh the same page it was on
      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def stop
      authorize! :stop, @server
      RocketJob::Subscribers::Server.publish(:stop, server_id: @server.id)
      flash[:success] = t(:success, scope: %i[server update_one], action: "stop", name: @server.name)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      authorize! :destroy, @server
      @server.destroy
      flash[:success] = t(:success, scope: %i[server destroy])

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      authorize! :pause, @server
      RocketJob::Subscribers::Server.publish(:pause, server_id: @server.id)
      flash[:success] = t(:success, scope: %i[server update_one], action: "pause", name: @server.name)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      authorize! :resume, @server
      RocketJob::Subscribers::Server.publish(:resume, server_id: @server.id)
      flash[:success] = t(:success, scope: %i[server update_one], action: "resume", name: @server.name)

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    private

    def authorize_read
      authorize! :read, RocketJob::Server
    end

    def render_datatable(servers, description)
      respond_to do |format|
        format.html do
          @description = description
          @states      = RocketJob::Server.aasm.states.map { |s| s.name.to_s }
          @states << "zombie"

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
        flash[:danger] = t(:failure, scope: %i[server find], id: params[:id])

        redirect_to(servers_path)
      end
    end

    def show_sidebar
      @servers_sidebar = true
    end
  end
end
