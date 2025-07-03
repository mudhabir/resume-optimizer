require 'open-uri'
require 'nokogiri'

class OptimizerController < ApplicationController
    protect_from_forgery with: :null_session
    include OptimizerHelper
    include MagicContentHelper

    def index
        optimized_resumes = current_user.resume_optimizers
        render json: optimized_resumes, status: :ok
    end

    def show
        optimizer_session = current_user.resume_optimizers.find(params[:id])
        render json: optimizer_session, status: :ok
    end

    def upload
        uploaded_file = params[:file]

        if uploaded_file.present? && uploaded_file.content_type.in?(['application/pdf', 'application/vnd.openxmlformats-officedocument.wordprocessingml.document'])
            filename = file_name_unique(uploaded_file.original_filename)
            save_dir = Rails.root.join('public', 'uploads')
        
            save_path = save_dir.join(filename)
        
            File.open(save_path, 'wb') do |file|
                file.write(uploaded_file.read)
            end

            optimized_resume = OptimizerSession.new(user_id: current_user.id, file_name: filename, status: OptimizerSession::STATUS[:RESUME_UPLOADED])
            optimized_resume.save!
        
            render json: { message: "File uploaded successfully", file_url: "/uploads/#{filename}" }, status: :ok
        else
            render json: { error: "Please upload a valid PDF file" }, status: :bad_request
        end
    end

    def job_description
        input_type = params[:type]
        content = params[:content]
        job_title = params[:job_title]

        if input_type.blank? || content.blank?
          render json: { error: "Both 'type' and 'content' parameters are required." }, status: :bad_request
          return
        end

        optimizer_session = OptimizerSession.find_by(id: params['session_id'].to_i )
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
            "sessionId": params['session_id'],
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
end
