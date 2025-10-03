require_relative '../../../lib/docx/questions'

# Extract text from DOCX and save to a versioned TXT file
DOCX_PATH = File.expand_path('p6.docx', __dir__)
DIR = File.dirname(__FILE__)

# Find latest version number
base = File.join(DIR, 'p6_extracted_v')
existing = Dir.glob(base + '*.txt')
latest = existing.map { |f| f[/v(\d+)\.txt$/, 1].to_i }.max || 0
next_version = latest + 1
output_path = File.join(DIR, "p6_extracted_v#{next_version}.txt")

extracted = Docx::Questions.extract_text(DOCX_PATH)
File.write(output_path, extracted)
puts "Extracted text saved to #{output_path}"
