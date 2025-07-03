# app/controllers/sessions_controller.rb
class SessionsController < ApplicationController
  skip_before_action :authenticate_user!
  
  def create
    user = User.find_by(email: params[:email])
    if user&.authenticate(params[:password])
      render json: { token: generate_token(user) }, status: :ok
    else
      render json: { error: "Invalid credentials" }, status: :unauthorized
    end
  end

#   def google_auth
#     user_info = request.env['omniauth.auth']
#     user = User.find_or_create_by(provider: user_info['provider'], uid: user_info['uid']) do |u|
#       u.email = user_info['info']['email']
#       u.name = user_info['info']['name']
#       u.password = SecureRandom.hex(10) # Random password, not used
#     end

#     render json: { token: generate_token(user) }, status: :ok
#   end
end