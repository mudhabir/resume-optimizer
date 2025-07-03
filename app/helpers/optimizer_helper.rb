require 'pdf-reader'
module OptimizerHelper
    def extract_text(url)
        html = URI.open(url).read
        doc = Nokogiri::HTML(html)
        doc.css('script, style, noscript').remove
        doc.text.strip.gsub(/\s+/, ' ') # Get all visible text, squish extra whitespace
    end

    def get_resume_text(file_name)
        file_path = Rails.root.join('public', 'uploads', file_name)
        
        if File.extname(file_name).downcase == '.pdf'
            reader = PDF::Reader.new(file_path)
            text = reader.pages.map(&:text).join(' ')
            text.strip
        else
            # For non-PDF files, return empty string or handle other formats
            # You might want to add support for .docx files here
            ""
        end
    rescue => e
        Rails.logger.error "Error reading PDF file #{file_name}: #{e.message}"
        ""
    end

    def file_name_unique(file_name)
        (OptimizerSession.maximum(:id).to_i + 1).to_s + '_' + file_name
    end

    def get_original_file_name(file_name)
        file_name.split('_')[1..-1].join('_')
    end
end
