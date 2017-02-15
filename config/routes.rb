RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update, :destroy, :edit] do
    collection do
      get :running,   to: 'jobs#running'
      get :scheduled, to: 'jobs#scheduled'
      get :completed, to: 'jobs#completed'
      get :queued,    to: 'jobs#queued'
      get :paused,    to: 'jobs#paused'
      get :failed,    to: 'jobs#failed'
      get :aborted,   to: 'jobs#aborted'
    end

    member do
      patch :abort
      patch :fail
      patch :pause
      patch :resume
      patch :retry
      patch :run_now
      get   :exceptions
    end
    resources :failures, controller: 'jobs/failures', only: :index
  end

  resources :active_workers, only: :index

  resources :servers, only: [:index, :destroy] do
    collection do
      get :starting, to: 'servers#starting'
      get :running,  to: 'servers#running'
      get :paused,   to: 'servers#paused'
      get :stopping, to: 'servers#stopping'
      get :zombie,   to: 'servers#zombie'
    end

    member do
      patch :stop
      patch :pause
      patch :resume
    end
    collection do
      patch :update_all
    end
  end

  resources :dirmon_entries do
    collection do
      get :pending,  to: 'dirmon_entries/index_filters#pending'
      get :enabled,  to: 'dirmon_entries/index_filters#enabled'
      get :failed,   to: 'dirmon_entries/index_filters#failed'
      get :disabled, to: 'dirmon_entries/index_filters#disabled'
    end

    member do
      put :enable
      put :disable
    end
  end

  root to: "jobs#running"
end
