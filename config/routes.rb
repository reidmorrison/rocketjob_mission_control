RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update, :destroy, :edit] do
    collection do
      get :running,   to: 'jobs/index_filters#running'
      get :scheduled, to: 'jobs/index_filters#scheduled'
      get :completed, to: 'jobs/index_filters#completed'
      get :queued,    to: 'jobs/index_filters#queued'
      get :paused,    to: 'jobs/index_filters#paused'
      get :failed,    to: 'jobs/index_filters#failed'
      get :aborted,   to: 'jobs/index_filters#aborted'
    end

    member do
      patch :abort
      patch :fail
      patch :pause
      patch :resume
      patch :retry
      patch :run_now
    end
    resources :failures, controller: 'jobs/failures', only: :index
  end

  resources :active_processes, only: :index

  resources :workers, only: [:index, :destroy] do
    collection do
      get :starting, to: 'workers/index_filters#starting'
      get :running, to: 'workers/index_filters#running'
      get :paused, to: 'workers/index_filters#paused'
      get :stopping, to: 'workers/index_filters#stopping'
      get :zombie, to: 'workers/index_filters#zombies'
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
      get :pending,   to: 'dirmon_entries/index_filters#pending'
      get :enabled, to: 'dirmon_entries/index_filters#enabled'
      get :failed, to: 'dirmon_entries/index_filters#failed'
      get :disabled,    to: 'dirmon_entries/index_filters#disabled'
    end

    member do
      put :enable
      put :disable
    end
  end

  root to: "jobs/index_filters#running"
end
