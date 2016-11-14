module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    before_filter :find_server, only: [:stop, :pause, :resume, :destroy]
    before_filter :show_sidebar

    def index
      @servers = RocketJob::Server.all.sort(name: 1)
      respond_to do |format|
        format.html
        format.json { render(json: ServersDatatable.new(view_context, @servers)) }
      end
    end

    VALID_STATES = {
      stop_all:        'stopped',
      pause_all:       'paused',
      resume_all:      'resumed',
      destroy_zombies: 'destroyed if zombified',
    }

    def update_all
      server_action = params[:server_action].to_sym
      if VALID_STATES.keys.include?(server_action)
        RocketJob::Server.send(server_action.to_sym)
        flash[:notice] = t(:success, scope: [:server, :update_all], server_action: VALID_STATES[server_action])
      else
        flash[:alert] = t(:invalid, scope: [:server, :update_all])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def stop
      if @server.stop!
        flash[:notice] = t(:success, scope: [:server, :stop])
      else
        flash[:alert] = t(:failure, scope: [:server, :stop])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      if @server.nil? || @server.destroy
        flash[:notice] = t(:success, scope: [:server, :destroy])
      else
        flash[:alert] = t(:failure, scope: [:server, :destroy])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      if @server.pause!
        flash[:notice] = t(:success, scope: [:server, :pause])
      else
        flash[:alert] = t(:failure, scope: [:server, :pause])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      if @server.resume!
        flash[:notice] = t(:success, scope: [:server, :resume])
      else
        flash[:alert] = t(:failure, scope: [:server, :resume])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    private

    def find_server
      @server = RocketJob::Server.find(params[:id])
    end

    def show_sidebar
      @servers_sidebar = true
    end
  end
end
