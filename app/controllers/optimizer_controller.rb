require 'open-uri'
require 'nokogiri'

class OptimizerController < ApplicationController
    include OptimizerHelper
    include MagicContentHelper

    def index
        response = current_user.optimizer_sessions.each_with_object([]) do |session, obj|
            obj << { id: session.id, input_file_name: session.file_name, status: OptimizerSession::STATUS_ID_TO_NAME[session.status]}
        end
        render json: response, status: :ok
    end

    def show
        optimizer_session = current_user.optimizer_sessions.find(params[:id])
        render json: optimizer_session, status: :ok
    end

    def process_resume_and_jd
        byebug
        jd_data = JSON.parse(params['jd_data'])
        input_type = jd_data['type']
        content = jd_data['content']
        job_title = jd_data['job_title']

        if input_type.blank? || content.blank?
          render json: { error: "Both 'type' and 'content' parameters are required." }, status: :bad_request
          return
        end

        uploaded_file = params[:file]
        if uploaded_file.present? && uploaded_file.content_type.in?(['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
            filename = file_name_unique(uploaded_file.original_filename)
            save_dir = Rails.root.join('public', 'uploads')
        
            save_path = save_dir.join(filename)
        
            File.open(save_path, 'wb') do |file|
                file.write(uploaded_file.read)
            end

            optimizer_session = OptimizerSession.new(user_id: current_user.id, file_name: filename, status: OptimizerSession::STATUS[:RESUME_UPLOADED])
        else
            render json: { error: "Please upload a valid PDF file" }, status: :bad_request
            return
        end

        if input_type == "text"
            optimizer_session.job_description_content = content
            optimizer_session.status = OptimizerSession::STATUS[:JOB_DESCRIPTION_PROVIDED]
            optimizer_session.save!
        elsif input_type == "url"
          begin
            description = extract_text(content)
            optimizer_session.job_description_url = content
            optimizer_session.job_description_content = scrape_jd(description)
            optimizer_session.status = OptimizerSession::STATUS[:JOB_DESCRIPTION_PROVIDED]
            optimizer_session.save!
          rescue => e
            render json: { error: "Failed to fetch or parse job description from URL: #{e.message}" }, status: :bad_request
            return
          end
        else
          render json: { error: "Invalid 'type' parameter. Must be 'text' or 'url'." }, status: :bad_request
          return
        end

        render json: {
            "sessionId": optimizer_session.id,
            "file_url": "/uploads/#{filename}",
            "status": "jd_provided",
            "jd_content": optimizer_session.job_description_content,
            "message": "Job description saved successfully."
        }, status: :ok
    end

    def start_analysis
        optimizer_session = OptimizerSession.find_by(id: params['session_id'].to_i )
        if optimizer_session.nil?
            render json: { error: "Session not found. Please create a session first." }, status: :not_found
            return
        end

        if optimizer_session.file_name.blank? || optimizer_session.job_description_content.blank?
            render json: { error: "Resume file and description are required to start analysis." }, status: :bad_request
            return
        end

        if current_user.credit_points <= 0
            render json: { error: "You have used up all your credits" }, status: :bad_request
            return
        end


        resume_text = get_resume_text(optimizer_session.file_name)
        analysis_result = analyze_resume(resume_text, optimizer_session.job_description_content)
        optimizer_session.analysis_result = analysis_result
        optimizer_session.status = OptimizerSession::STATUS[:ANALYSIS_COMPLETE]
        optimizer_session.save!

        current_user.credit_points -= 1
        current_user.save!

        render json: {
            status: "analysis_complete",
            analysis_result: {
                missing_skills: analysis_result['missing_mandatory_skills'] + analysis_result['missing_optional_skills'],
                optimization_suggestions: analysis_result['suggestions'],
                score: analysis_result['ats_score']
            },
            credit_points_remaining: current_user.credit_points
        }, status: :ok
    end

    def optimized_resume
        optimizer_session = OptimizerSession.find_by(id: params['session_id'].to_i )
        if optimizer_session.nil?
            render json: { error: "Session not found. Please create a session first." }, status: :not_found
            return
        end

        if optimizer_session.file_name.blank? || optimizer_session.job_description_content.blank?
            render json: { error: "Resume file and description are required to start analysis." }, status: :bad_request
            return
        end

        if optimizer_session.analysis_result.blank?
            render json: { error: "Analysis must be completed before generating optimized resume." }, status: :bad_request
            return
        end

        begin
            # Get the original resume text
            resume_text = get_resume_text(optimizer_session.file_name)
            
            # Generate optimized content using AI
            optimized_content = optimize_resume_content(resume_text, optimizer_session.job_description_content, optimizer_session.analysis_result)
            
            # Generate new filename for optimized resume
            original_filename = get_original_file_name(optimizer_session.file_name)
            original_extension = File.extname(original_filename).downcase
            
            # Generate PDF filename regardless of original format
            base_name = File.basename(original_filename, '.*')
            optimized_filename = file_name_unique("optimized_#{base_name}.pdf")
            
            # Generate properly formatted PDF
            generate_optimized_pdf(optimized_content, optimizer_session.file_name, optimized_filename)
            
            # Update optimizer session with optimized file info
            optimizer_session.optimized_file_name = optimized_filename
            optimizer_session.status = OptimizerSession::STATUS[:OPTIMIZED]
            optimizer_session.save!
            
            render json: { 
                message: "Optimized resume generated successfully",
                optimized_file_url: "/uploads/#{optimized_filename}",
                session_id: optimizer_session.id,
                status: "optimized",
                original_format: original_extension,
                optimized_format: ".pdf"
            }, status: :ok
            
        rescue => e
            Rails.logger.error "Error generating optimized resume: #{e.message}"
            render json: { error: "Failed to generate optimized resume: #{e.message}" }, status: :internal_server_error
        end
    end
end
