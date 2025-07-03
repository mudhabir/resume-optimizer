Rails.application.routes.draw do
  post 'api/session/create', to: 'optimizer#session_create'
  post 'api/resume/upload', to: 'optimizer#upload'
  post 'api/job_description', to: 'optimizer#job_description'
  post 'api/analyze/start', to: 'optimizer#start_analysis'

  get 'api/optimizer_sessions', to: 'optimizer#index'
  get 'api/optimizer_sessions/:id', to: 'optimizer#show'

  post 'api/auth/sign_up', to: 'users#create'
  post 'api/auth/sign_in', to: 'sessions#create'
end
