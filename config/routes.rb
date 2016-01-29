RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update, :destroy] do
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
    end
    resources :failures, controller: 'jobs/failures', only: :index
  end

  resources :active_processes, only: :index

  resources :workers, only: [:index, :destroy] do
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
    member do
      put :enable
      put :disable
    end
  end

  root to: "jobs#index"
end
