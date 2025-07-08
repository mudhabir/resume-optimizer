class User < ApplicationRecord
    devise :omniauthable, omniauth_providers: [:google_oauth2]
    
    self.table_name = 'users'
    has_secure_password

    has_many :optimizer_sessions, dependent: :destroy
  
    validates :email, presence: true, uniqueness: true

    validates :password, presence: true, confirmation: true,
    length: { minimum: 8 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+\z/,
      message: 'must include at least one uppercase letter, one lowercase letter, one digit, and one special character'
    }, if: :password_required?


    def self.from_omniauth(auth)
      where(provider: auth.provider, uid: auth.uid).first_or_create do |user|
        user.email = auth.info.email
        user.password = SecureRandom.hex(16)
        user.name = auth.info.name   # You might want to add this field
      end
    end

    private

    # Only validate password if new record or password is being set
    def password_required?
      provider.blank? && (new_record? || password.present?)
    end
end