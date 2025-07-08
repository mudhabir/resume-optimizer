# app/controllers/api_controller.rb
class ApiController < ActionController::API
    before_action :authenticate_user!
  
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
end