# db/migrate/20240610120000_create_optimizer_sessions.rb
class CreateOptimizerSessions < ActiveRecord::Migration[7.1]
    def change
      create_table :optimizer_sessions do |t|
        t.references :user, null: false, foreign_key: true
        t.integer :status, default: 0, null: false
        t.string :file_name
        t.text :job_description_content
        t.text :job_description_url
        t.json :analysis_result
        t.string :optimized_file_name
  
        t.timestamps
      end
    end
end