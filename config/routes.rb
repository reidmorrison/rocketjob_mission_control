RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update, :destroy] do
    member do
      patch :abort
      patch :fail
      patch :pause
      patch :resume
      patch :retry
    end
    collection do
      get :running
    end
    resources :failures, controller: 'jobs/failures', only: [:index]
  end

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
