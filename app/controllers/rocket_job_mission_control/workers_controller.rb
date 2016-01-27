module RocketJobMissionControl
  class WorkersController < RocketJobMissionControl::ApplicationController
    before_filter :find_worker, only: [:stop, :pause, :resume, :destroy]
    before_filter :show_sidebar

    def index
      @workers = RocketJob::Worker.sort(:name)
    end

    VALID_STATES = {
      stop_all:        'stopped',
      pause_all:       'paused',
      resume_all:      'resumed',
      destroy_zombies: 'destroyed if zombified',
    }

    def update_all
      worker_action = params[:worker_action].to_sym
      if VALID_STATES.keys.include?(worker_action)
        RocketJob::Worker.send(worker_action.to_sym)
        flash[:notice] = t(:success, scope: [:worker, :update_all], worker_action: VALID_STATES[worker_action])
      else
        flash[:alert] = t(:invalid, scope: [:worker, :update_all])
      end

      respond_to do |format|
        format.html { redirect_to workers_path }
      end
    end

    def stop
      if @worker.stop!
        flash[:notice] = t(:success, scope: [:worker, :stop])
      else
        flash[:alert] = t(:failure, scope: [:worker, :stop])
      end

      respond_to do |format|
        format.html { redirect_to workers_path }
      end
    end

    def destroy
      if @worker.destroy
        flash[:notice] = t(:success, scope: [:worker, :destroy])
      else
        flash[:alert] = t(:failure, scope: [:worker, :destroy])
      end

      respond_to do |format|
        format.html { redirect_to workers_path }
      end
    end

    def pause
      if @worker.pause!
        flash[:notice] = t(:success, scope: [:worker, :pause])
      else
        flash[:alert] = t(:failure, scope: [:worker, :pause])
      end

      respond_to do |format|
        format.html { redirect_to workers_path }
      end
    end

    def resume
      if @worker.resume!
        flash[:notice] = t(:success, scope: [:worker, :resume])
      else
        flash[:alert] = t(:failure, scope: [:worker, :resume])
      end

      respond_to do |format|
        format.html { redirect_to workers_path }
      end
    end

    private

    def find_worker
      @worker = RocketJob::Worker.find(params[:id])
    end

    def show_sidebar
      @workers_sidebar = true
    end
  end
end
