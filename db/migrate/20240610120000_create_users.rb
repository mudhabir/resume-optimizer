# db/migrate/20240610120000_create_users.rb
class CreateUsers < ActiveRecord::Migration[7.1]
    def change
      create_table :users do |t|
        t.string :email, null: false, index: { unique: true }
        t.string :name
        t.string :password_digest
        t.integer :credit_points, default: 3
  
        t.timestamps
      end
    end
  end