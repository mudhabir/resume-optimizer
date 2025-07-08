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
end