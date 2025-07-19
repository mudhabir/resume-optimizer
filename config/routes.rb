Rails.application.routes.draw do
  # get 'home/index'
  post 'api/session/create', to: 'optimizer#session_create'
  post 'api/process_resume_and_jd', to: 'optimizer#process_resume_and_jd'
  post 'api/analyze/start', to: 'optimizer#start_analysis'
  post 'api/resume/optimize', to: 'optimizer#optimized_resume'

  get 'api/optimizer_sessions', to: 'optimizer#index'
  get 'api/optimizer_sessions/:id', to: 'optimizer#show'

  post 'api/auth/sign_up', to: 'users#create'
  post 'api/auth/sign_in', to: 'sessions#create'

  devise_for :users, controllers: { omniauth_callbacks: 'users/omniauth_callbacks' }, skip: [:sessions, :registrations, :passwords]

  # root "home#index"
end
