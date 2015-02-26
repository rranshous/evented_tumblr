require 'streamworker'
require 'feedjira'

name 'blog-observer'

handle 'tumblr' => 'blog-noted' do |state, event|
  blog_href = event[:body]['href']
  url = "#{blog_href}/rss"
  log "handling: #{blog_href}"
  feed = Feedjira::Feed.fetch_and_parse([url])[url]
  if feed.is_a? Fixnum
    log "bad feed url: #{blog_href}"
    emit 'tumblr', 'blog-not-found', { href: blog_href }
  else
    blog_data = {
      'href' => feed.url,
      'timestamp' => nil
    }
    if feed.last_modified
      blog_data.merge!({ 'timestamp' => feed.last_modified.iso8601 })
    end
    log "emitting blog observed"
    emit 'tumblr', 'blog-observed', blog_data
  end
end
