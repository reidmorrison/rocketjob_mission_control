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
  end

  resources :servers, only: [:index, :destroy] do
    member do
      patch :stop
      patch :pause
      patch :resume
    end
    collection do
      patch :update_all
    end
  end

  root to: "jobs#index"
end
