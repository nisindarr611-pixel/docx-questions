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

        # Iterate through paragraphs and their children
        doc.xpath('//w:p', namespaces).each do |para|
          para.children.each do |node|
            if node.name == 'r'
              # Run: may contain text, drawing, or equation
              text_node = node.at_xpath('.//w:t', namespaces)
              text_content << text_node.text if text_node
              # Check for image
              if node.at_xpath('.//w:drawing', namespaces) || node.at_xpath('.//w:pict', namespaces)
                text_content << '<img>'
              end
              # Check for MathType/OfficeMath object
              if node.at_xpath('.//m:oMath', namespaces) || node.at_xpath('.//m:oMathPara', namespaces)
                text_content << '<eqn>'
              end
              # Check for OLE object (MathType equation or other)
              if node.at_xpath('.//w:object', namespaces) || node.at_xpath('.//o:OLEObject', namespaces)
                text_content << '<eqn>'
              end
            elsif node.name == 'drawing' || node.name == 'pict'
              text_content << '<img>'
            elsif node.name == 'oMath' || node.name == 'oMathPara'
              text_content << '<eqn>'
            elsif node.name == 'object'
              text_content << '<eqn>'
            end
          end
        end
      end

      text_content.join(' ')
    end
  end
end
