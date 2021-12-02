# This file fetches submitted guestbook entries from Netlify's API and updates a static data file.
# Use your secret values below (never commit them!) and run `ruby update_guestbook.rb`.

require 'httparty'

NETLIFY_PERSONAL_ACCESS_TOKEN = 'R53yACs27R2c9R2Y4ijDkzIW3YF_bheNfICzT1jGAfs'
NETLIFY_SITE_ID =               '28f1c9cd-17d8-4335-b8ce-3871d5c9e917'
NETLIFY_FORM_ID =               '61a86edc4fc1690008432673'

headers = {
  'Authorization': "Bearer #{NETLIFY_PERSONAL_ACCESS_TOKEN}"
}

# Get form submissions from Netlify API
raw_messages_from_api = JSON.parse(HTTParty.get("https://api.netlify.com/api/v1/sites/#{NETLIFY_SITE_ID}/forms/#{NETLIFY_FORM_ID}/submissions", headers: headers).to_s)

# Parse raw messages and index by ID
messages_from_api = {}
raw_messages_from_api.each do |raw_message|
  messages_from_api[raw_message['id']] = {
    'id' => raw_message['id'],
    'author' => CGI.escapeHTML(raw_message['name']),
    'timestamp' => DateTime.parse(raw_message['created_at']).strftime('%FT%T%:z'),
    'body' => CGI.escapeHTML(raw_message['body']),
  }
end

# Index existing messages by ID
existing_messages = YAML.load(File.read('_data/guestbook_messages.yml')) || []
existing_messages_by_id = existing_messages.each_with_object({}) do |message, existing_messages_by_id|
  existing_messages_by_id[message['id']] = message
end

# Merge messages from API with existing messages using message IDs as unique key
all_messages = existing_messages_by_id
  .merge(messages_from_api)
  .values
  .sort_by { |m| m['timestamp'] }

# Update static data file
File.write('_data/guestbook_messages.yml', YAML.dump(all_messages))