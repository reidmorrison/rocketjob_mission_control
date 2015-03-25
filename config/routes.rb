RocketJobMissionControl::Engine.routes.draw do

  resources :jobs, only: [:index, :show, :update] do
    post :retry,        on: :member
  end

  resources :servers, only: [:index, :destroy] do
    patch :stop,   on: :member
    patch :pause,  on: :member
    patch :resume, on: :member
  end

  get "/status" => "application#status", as: "status"
  get "/scheduled" => "application#scheduled", as: "scheduled"
  get "/overview" => "application#overview", as: "overview"
  get "/:id/download" => "application#download", as: "download"

  root to: "jobs#index"
end
