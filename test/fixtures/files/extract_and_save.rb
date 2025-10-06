require_relative '../../../lib/docx/questions'

# Extract text from DOCX and save to p6_extracted.txt (overwrite each time)
DOCX_PATH = File.expand_path('p6.docx', __dir__)
OUTPUT_PATH = File.join(File.dirname(__FILE__), 'p6_extracted.txt')

extracted = Docx::Questions.extract_text(DOCX_PATH)
File.write(OUTPUT_PATH, extracted)
puts "Extracted text saved to #{OUTPUT_PATH}"
