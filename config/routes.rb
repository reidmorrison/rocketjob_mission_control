RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update] do
    member do
      patch :retry
      patch :abort
      patch :pause
      patch :resume
      patch :fail
    end
    collection do
      get :running
    end
  end

  resources :servers, only: [:index, :destroy] do
    patch :stop,   on: :member
    patch :pause,  on: :member
    patch :resume, on: :member
  end

  root to: "jobs#index"
end
