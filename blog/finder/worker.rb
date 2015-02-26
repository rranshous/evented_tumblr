require 'feedjira'
require 'httparty'
require 'streamworker'

URLS_FILE_URL = ENV['URLS_FILE_URL']
SLEEP_TIME = ENV['SLEEP_TIME'] ? ENV['SLEEP_TIME'].to_i : 60 * 10

name 'blog-finder'

loop do
  log 'Downloading urls'
  url_lines = HTTParty.get(URLS_FILE_URL).parsed_response.split("\n")
  blog_urls = url_lines.select{|l| !l.chomp.start_with?('#') && l.chomp.length>0}
  log "Found #{blog_urls.length} URLS"
  blog_urls.each do |url|
    log "emitting blog-noted #{url}"
    emit 'tumblr', 'blog-noted', { href: url }
  end
  sleep SLEEP_TIME
end
