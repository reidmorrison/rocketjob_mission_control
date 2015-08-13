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

  resources :dirmon_entries, only: [:index, :show, :update, :destroy, :new, :create, :edit] do
    member do
      put :enable
      put :disable
      patch :update
    end
  end

  post "/dirmon_entries/new"
  post "/dirmon_entries/edit"

  root to: "jobs#index"
end
