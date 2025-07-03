# app/controllers/users_controller.rb
class UsersController < ApplicationController
    skip_before_action :authenticate_user!

    def create
        user = User.new(user_params)
        if user.save
            render json: { message: 'Signup successful' }, status: :created
        else
            render json: { errors: user.errors.full_messages }, status: :unprocessable_entity
        end
    end
  
    private
  
    def user_params
        params.permit(:name,:email, :password, :password_confirmation)
    end
  end