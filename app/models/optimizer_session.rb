# app/models/optimizer_session.rb
class OptimizerSession < ApplicationRecord
    self.table_name = 'optimizer_sessions'
    belongs_to :user
  
    validates :file_name, presence: true

    STATUS = {
        RESUME_UPLOADED: 0,
        JOB_DESCRIPTION_PROVIDED: 1,
        ANALYSIS_COMPLETE: 2,
        OPTIMIZED: 3
    }
end