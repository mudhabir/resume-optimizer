class User < ApplicationRecord
    self.table_name = 'users'
    has_secure_password
  
    has_many :resume_optimizers, dependent: :destroy
  
    validates :email, presence: true, uniqueness: true

    validates :password, presence: true, confirmation: true,
    length: { minimum: 8 },
    format: {
      with: /\A(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[\W_]).+\z/,
      message: 'must include at least one uppercase letter, one lowercase letter, one digit, and one special character'
    }, if: :password_required?

    private

    # Only validate password if new record or password is being set
    def password_required?
        new_record? || !password.nil?
    end
end