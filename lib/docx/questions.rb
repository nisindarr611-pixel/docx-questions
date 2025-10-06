# frozen_string_literal: true

require_relative "questions/version"
require "zip"
require "nokogiri"

module Docx
  module Questions
    class Error < StandardError; end

    def self.extract_text(docx_path)
      text_content = []

      Zip::File.open(docx_path) do |zip_file|
        # Find and read the main document XML file
        document_xml = zip_file.find_entry("word/document.xml")
        next unless document_xml

        # Parse the XML content
        doc = Nokogiri::XML(document_xml.get_input_stream.read)

        # Define namespaces for XPath queries
        namespaces = {
          'w' => 'http://schemas.openxmlformats.org/wordprocessingml/2006/main',
          'm' => 'http://schemas.openxmlformats.org/officeDocument/2006/math',
          'o' => 'urn:schemas-microsoft-com:office:office'
        }

        # Iterate through paragraphs
        doc.xpath('//w:p', namespaces).each do |para|
          para_tokens = []
          runs = para.xpath('.//w:r', namespaces)
          i = 0
          while i < runs.size
            run = runs[i]
            text_node = run.at_xpath('.//w:t', namespaces)
            text = text_node&.text
            # Debug output
            puts "DEBUG: run text='#{text}', vertAlign='#{run.at_xpath('.//w:vertAlign', namespaces)&.[]('val')}'"
            if text.nil? || text.strip.empty?
              i += 1
              next
            end
            # Pattern-based subscript detection
            if i < runs.size - 1
              next_run = runs[i + 1]
              next_text_node = next_run.at_xpath('.//w:t', namespaces)
              next_text = next_text_node&.text
              if text.match?(/^[a-zA-Z]$/) && next_text && next_text.match?(/^\d$/)
                para_tokens << "#{text}_{#{next_text}}"
                i += 2
                next
              end
            end
            para_tokens << text
            i += 1
          end
          para_text = para_tokens.join
          # Add line breaks at required places
          # Before image
          if para.at_xpath('.//w:drawing', namespaces) || para.at_xpath('.//w:pict', namespaces)
            para_text << "\n"
            para_text << '<img>'
            para_text << "\n"
          end
          # After image and before options
          para_text.gsub!(/<img>(?!\n)/, "<img>\n")
          # Add line break after each option marker (a), (b), (c), (d)
          para_text.gsub!(/([a-d]\))/) { |m| "#{m}\n" }
          # Add line break before Key:
          para_text.gsub!(/(Key:)/, "\n\\1")
          # Add line break before Hint:
          para_text.gsub!(/(Hint:)/, "\n\\1")
          text_content << para_text unless para_text.strip.empty?
          # Insert <img> if image is present in paragraph
          if para.at_xpath('.//w:drawing', namespaces) || para.at_xpath('.//w:pict', namespaces)
            text_content << '<img>'
          end
          # Insert <eqn> if MathType or OLE object is present in paragraph
          if para.at_xpath('.//m:oMath', namespaces) || para.at_xpath('.//m:oMathPara', namespaces) || para.at_xpath('.//w:object', namespaces) || para.at_xpath('.//o:OLEObject', namespaces)
            text_content << '<eqn>'
          end
        end
      end

      text_content.join(' ')
    end
  end
end
