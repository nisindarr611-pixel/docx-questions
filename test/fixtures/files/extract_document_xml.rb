require 'zip'

# Extract word/document.xml from p6.docx and save to document.xml
DOCX_PATH = File.expand_path('p6.docx', __dir__)
OUTPUT_PATH = File.expand_path('document.xml', __dir__)

Zip::File.open(DOCX_PATH) do |zip_file|
  entry = zip_file.find_entry('word/document.xml')
  if entry
    File.write(OUTPUT_PATH, entry.get_input_stream.read)
    puts "Saved word/document.xml to #{OUTPUT_PATH}"
  else
    puts "word/document.xml not found in #{DOCX_PATH}"
  end
end
