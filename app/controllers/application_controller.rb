class ApplicationController < ActionController::Base
    before_action :authenticate_user!
    skip_before_action :verify_authenticity_token

    attr_reader :current_user

    private

    def current_user
      @current_user
    end

    def authenticate_user!
      token = request.headers['Authorization']&.split(' ')&.last
  
      if token.blank?
        render json: { error: 'Missing token' }, status: :unauthorized and return
      end
  
      begin
        payload = JWT.decode(token, ENV['JWT_SECRET_KEY'])[0]
        @current_user = User.find(payload['user_id'])
  
      rescue JWT::ExpiredSignature
        render json: { error: 'Token has expired' }, status: :unauthorized
  
      rescue JWT::DecodeError, ActiveRecord::RecordNotFound
        render json: { error: 'Invalid token' }, status: :unauthorized
      end
    end
  
    def generate_token(user)
      payload = { user_id: user.id, exp: 24.hours.from_now.to_i }
      JWT.encode(payload, ENV['JWT_SECRET_KEY'])
    end
end
