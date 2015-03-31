module RocketJobMissionControl
  class ServersController < RocketJobMissionControl::ApplicationController
    before_filter :find_server, only: [:stop, :pause, :resume, :destroy]

    def index
      @servers = RocketJob::Server.sort(:name)
    end

    def stop
      @server.stop!

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def destroy
      @server.destroy

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def pause
      @server.pause!

      respond_to do |format|
        format.html { redirect_to servers_path }
      end
    end

    def resume
      @server.resume!

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
