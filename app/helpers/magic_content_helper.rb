require 'uri'
require 'net/http'

module MagicContentHelper

    SCRAPE_JD_PROMPT = <<~PROMPT
    Extract all skills and experiences mentioned in the following job post. Categorize them into two groups: Mandatory Skills and Optional Skills — only if such distinction is clear in the text.
  
    For each skill, preserve the entire original sentence or bullet point exactly as it appears in the job post.
  
    Important Instructions (strict):
    - Do not add or remove words from the original text.
    - Do not paraphrase.
    - Do not include any explanations, greetings, or comments.
    - Your response must include only the grouped skill text.
    - Output format: Exact lines of experiences and skills.
  PROMPT

    RESUME_ANALYSIS_PROMPT = <<~PROMPT
    Provide a JSON object containing the following fields only:
    - ats_score: numeric value representing the ATS score based on mandatory and non-mandatory skills. Do not include any other data, explanations, or extra text.
    - missing_mandatory_skills: list of missing mandatory skills as strings.
    -missing_optional_skills: list of missing non-mandatory (optional) skills as strings.
    - suggestions: list of suggestions to improve ATS score above 90%.

    Do not include any other data, explanations, or extra text. Respond only with this JSON object.
    PROMPT

    DEEPSEEK_MODEL = 'deepseek/deepseek-r1-0528-qwen3-8b:free'
    GOOGLE_GEMMA_MODEL = 'google/gemma-3n-e4b-it:free'

    def scrape_jd(content)
        url = URI("https://openrouter.ai/api/v1/chat/completions")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true
        
        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{ENV['OPENROUTER_SECRET']}"
        request["Content-Type"] = 'application/json'

        body = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {
                    "role": "user",
                    "content": "#{SCRAPE_JD_PROMPT}\n\n#{content}"
                }
            ]
        }
        request.body = body.to_json
        response = http.request(request)
        
        JSON.parse(response.read_body)['choices'][0]['message']['content']
    end

    def analyze_resume(resume_text, jd_text)
        Rails.logger.info "Starting resume analysis"
        url = URI("https://openrouter.ai/api/v1/chat/completions")
        http = Net::HTTP.new(url.host, url.port)
        http.use_ssl = true

        request = Net::HTTP::Post.new(url)
        request["Authorization"] = "Bearer #{ENV['OPENROUTER_SECRET']}"
        request["Content-Type"] = 'application/json'

        body = {
            "model": DEEPSEEK_MODEL,
            "messages": [
                {
                    "role": "user",
                    "content": "#{RESUME_ANALYSIS_PROMPT}\n\nRESUME:\n#{resume_text}\n\nJD:\n#{jd_text}"
                }
            ]
        }
        request.body = body.to_json
        response = http.request(request)
        json_stringified_response = JSON.parse(response.read_body)['choices'][0]['message']['content']
        cleaned_stringified_response = json_stringified_response.gsub(/```json|```/, '').strip
        JSON.parse(cleaned_stringified_response)
    end
end