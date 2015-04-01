module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    before_filter :find_server, only: [:stop, :pause, :resume, :destroy]

    def index
      @servers = RocketJob::Server.sort(:name)
    end

    def stop
      if @server.stop!
        flash[:notice] = t(:success, scope: [:server, :stop])
      else
        flash[:alert]  = t(:failure, scope: [:server, :stop])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      if @server.destroy
        flash[:notice] = t(:success, scope: [:server, :destroy])
      else
        flash[:alert]  = t(:failure, scope: [:server, :destroy])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      if @server.pause!
        flash[:notice] = t(:success, scope: [:server, :pause])
      else
        flash[:alert]  = t(:failure, scope: [:server, :pause])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      if @server.resume!
        flash[:notice] = t(:success, scope: [:server, :resume])
      else
        flash[:alert]  = t(:failure, scope: [:server, :resume])
      end

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    private

    def find_server
      @server = RocketJob::Server.find(params[:id])
    end
  end
end
