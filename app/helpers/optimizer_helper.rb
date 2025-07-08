require 'pdf-reader'
require 'prawn'
require 'prawn/table'
require 'docx'
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
        elsif File.extname(file_name).downcase == '.docx'
            doc = Docx::Document.open(file_path)
            doc.paragraphs.map(&:text).join(' ')
        else
            # For other file types, return empty string
            ""
        end
    rescue => e
        Rails.logger.error "Error reading file #{file_name}: #{e.message}"
        ""
    end

    def get_resume_structure(file_name)
        file_path = Rails.root.join('public', 'uploads', file_name)
        
        if File.extname(file_name).downcase == '.pdf'
            extract_pdf_structure(file_path)
        elsif File.extname(file_name).downcase == '.docx'
            extract_docx_structure(file_path)
        else
            { sections: [], format: 'plain' }
        end
    rescue => e
        Rails.logger.error "Error extracting structure from #{file_name}: #{e.message}"
        { sections: [], format: 'plain' }
    end

    def generate_optimized_pdf(optimized_content, original_file_name, output_file_name)
        file_path = Rails.root.join('public', 'uploads', output_file_name)
        original_structure = get_resume_structure(original_file_name)
        Prawn::Document.generate(file_path) do |pdf|
            pdf.font_families.update(
                'OpenSans' => {
                    normal: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Regular.ttf').to_s,
                    bold: Rails.root.join('app', 'assets', 'fonts', 'OpenSans-Bold.ttf').to_s
                }
            )
            
            # Set default font
            pdf.font 'OpenSans'
            
            # Parse optimized content into structured format
            sections = parse_optimized_content(optimized_content)
            
            sections.each_with_index do |section, index|
                if index > 0
                    pdf.move_down 20
                end
                
                # Section header
                if section[:title]
                    pdf.font 'OpenSans', style: :bold, size: 14
                    pdf.text section[:title], color: '333333'
                    pdf.move_down 10
                end
                
                # Section content
                pdf.font 'OpenSans', style: :normal, size: 10
                
                section[:content].each do |item|
                    case item[:type]
                    when 'bullet'
                        pdf.text "• #{item[:text]}", indent_paragraphs: 20
                        pdf.move_down 5
                    when 'paragraph'
                        pdf.text item[:text]
                        pdf.move_down 8
                    when 'heading'
                        pdf.font 'OpenSans', style: :bold, size: 12
                        pdf.text item[:text], color: '444444'
                        pdf.move_down 5
                        pdf.font 'OpenSans', style: :normal, size: 10
                    when 'contact'
                        pdf.text item[:text], align: :center
                        pdf.move_down 3
                    end
                end
            end
        end
        
        output_file_name
    rescue => e
        Rails.logger.error "Error generating PDF: #{e.message}"
        raise e
    end

    def parse_optimized_content(content)
        sections = []
        current_section = { title: nil, content: [] }
        
        lines = content.split("\n").map(&:strip).reject(&:empty?)
        
        lines.each do |line|
            if line.match(/^[A-Z\s]+$/) && line.length > 3 && line.length < 30
                # Likely a section header
                if current_section[:content].any?
                    sections << current_section
                    current_section = { title: line, content: [] }
                else
                    current_section[:title] = line
                end
            elsif line.start_with?('•', '-', '*') || line.match(/^\d+\./)
                # Bullet point
                current_section[:content] << { type: 'bullet', text: line.gsub(/^[•\-\*\d\.]\s*/, '') }
            elsif line.match(/^\w+.*:$/)
                # Sub-heading
                current_section[:content] << { type: 'heading', text: line }
            elsif line.match(/@|phone|email|linkedin|github/i)
                # Contact information
                current_section[:content] << { type: 'contact', text: line }
            else
                # Regular paragraph
                current_section[:content] << { type: 'paragraph', text: line }
            end
        end
        
        sections << current_section if current_section[:content].any?
        sections
    end

    def extract_pdf_structure(file_path)
        reader = PDF::Reader.new(file_path)
        structure = { sections: [], format: 'pdf' }
        
        reader.pages.each do |page|
            text = page.text
            # Basic structure extraction - can be enhanced further
            lines = text.split("\n").reject(&:empty?)
            
            lines.each do |line|
                if line.match(/^[A-Z\s]+$/) && line.length > 3
                    structure[:sections] << { type: 'header', text: line }
                elsif line.start_with?('•', '-', '*')
                    structure[:sections] << { type: 'bullet', text: line }
                else
                    structure[:sections] << { type: 'paragraph', text: line }
                end
            end
        end
        
        structure
    end

    def extract_docx_structure(file_path)
        doc = Docx::Document.open(file_path)
        structure = { sections: [], format: 'docx' }
        
        doc.paragraphs.each do |paragraph|
            text = paragraph.text.strip
            next if text.empty?
            
            # Determine paragraph type based on formatting
            if paragraph.style && paragraph.style.match(/heading/i)
                structure[:sections] << { type: 'header', text: text }
            elsif text.start_with?('•', '-', '*')
                structure[:sections] << { type: 'bullet', text: text }
            else
                structure[:sections] << { type: 'paragraph', text: text }
            end
        end
        
        structure
    end

    def file_name_unique(file_name)
        (OptimizerSession.maximum(:id).to_i + 1).to_s + '_' + file_name
    end

    def get_original_file_name(file_name)
        file_name.split('_')[1..-1].join('_')
    end
end
